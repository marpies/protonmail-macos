//
//  CoreDataService+Messages.swift
//  ProtonMail
//
//
//  Copyright (c) 2019 Proton Technologies AG
//
//  This file is part of ProtonMail.
//
//  ProtonMail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ProtonMail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonMail.  If not, see <https://www.gnu.org/licenses/>.

import Foundation
import CoreData
import Groot
import PromiseKit

extension CoreDataService: MessagesDatabaseManaging {
    
    func saveMessages(_ json: [[String : Any]], forUser userId: String, completion: @escaping () -> Void) {
        self.backgroundContext.performWith { ctx in
            guard let messages = self.parseMessages(json, context: ctx) else {
                DispatchQueue.main.async {
                    completion()
                }
                return
            }
            
            // Mark metadata fetched
            for message in messages {
                message.messageStatus = 1
            }
            
            if let error = ctx.saveUpstreamIfNeeded() {
                PMLog.D("Error saving messages \(error)")
            } else {
                PMLog.D("Success saving messages")
            }
            
            DispatchQueue.main.async {
                completion()
            }
        }
    }
    
    func loadMessage(id: String) -> Message? {
        var message: Message?
        
        self.mainContext.performAndWaitWith { ctx in
            message = self.loadMessage(id: id, context: ctx)
        }
        
        return message
    }
    
    func fetchMessages(forUser userId: String, labelId: String, olderThan time: Date?, converter: MessageToModelConverting, completion: @escaping ([Messages.Message.Response]) -> Void) {
        self.backgroundContext.performWith { ctx in
            let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Message")
            request.predicate = self.getPredicate(forUser: userId, labelId: labelId, time: time)
            request.sortDescriptors = [NSSortDescriptor(key: "time", ascending: false)]
            request.fetchLimit = 50
            
            do {
                if let messages = try ctx.fetch(request) as? [Message] {
                    let models: [Messages.Message.Response] = messages.map { converter.getMessage($0) }
                    
                    DispatchQueue.main.async {
                        completion(models)
                    }
                    return
                }
            } catch {
                PMLog.D("Error fetching labels \(error)")
            }
            
            DispatchQueue.main.async {
                completion([])
            }
        }
    }
    
    func cleanMessages(forUser userId: String, removeDrafts: Bool) -> Promise<Void> {
        return Promise { seal in
            self.enqueue(context: self.backgroundContext) { (context) in
                let fetch = NSFetchRequest<NSFetchRequestResult>(entityName: Message.Attributes.entityName)
                fetch.predicate = NSPredicate(format: "%K == %@", Message.Attributes.userID, userId)
                
                if removeDrafts {
                    if let messages = try? context.fetch(fetch) as? [NSManagedObject] {
                        messages.forEach({ context.delete($0) })
                        _ = context.saveUpstreamIfNeeded()
                    }
                    
                    self.setAppBadge(0)
                } else {
                    let draftID: String = MailboxSidebar.Item.draft.id
                    let results = (try? fetch.execute()) ?? []
                    
                    for obj in results {
                        guard let message = obj as? Message else { continue }
                        if let labels = message.labels.allObjects as? [Label],
                           labels.contains(where: { $0.labelID == draftID }) {
                            
                            if let attachments = message.attachments.allObjects as? [Attachment],
                               attachments.contains(where: { $0.attachmentID == "0" }) {
                                // If the draft is uploading attachments, don't delete it
                                continue
                            } else if message.isSending {
                                // If the draft is sending, don't delete it
                                continue
                            } else if let _ = UUID(uuidString: message.messageID) {
                                // If the message ID is UUiD, means hasn't created draft, don't delete it
                                continue
                            }
                            
                        }
                        if let dataObject = obj as? NSManagedObject {
                            context.delete(dataObject)
                        }
                    }
                    
                    _ = context.saveUpstreamIfNeeded()
                }
                
                seal.fulfill_()
            }
        }
    }
    
    func deleteMessage(id: String) {
        self.deleteMessages(ids: [id])
    }
    
    func deleteMessages(ids: [String]) {
        let context: NSManagedObjectContext = self.mainContext
        self.enqueue(context: self.mainContext) { ctx in
            for id in ids {
                self.deleteMessage(id: id, context: ctx)
            }
            
            if let error = context.saveUpstreamIfNeeded() {
                PMLog.D("error: \(error)")
            }
        }
    }
    
    func updateLabel(messageIds: [String], label: String, apply: Bool, userId: String) -> [Message]? {
        var updatedMessages: [Message]?
        
        self.mainContext.performAndWaitWith { ctx in
            guard let messages = self.getMessages(ids: messageIds, context: ctx) else { return }
            
            for message in messages {
                self.updateLabel(forMessage: message, labelId: label, userId: userId, apply: apply, context: ctx)
            }
            
            let error = ctx.saveUpstreamIfNeeded()
            if let error = error {
                PMLog.D(" error: \(error)")
            } else {
                updatedMessages = messages
                
                self.notifyConversationCountsUpdate(userId: userId)
            }
        }
        
        return updatedMessages
    }
    
    func moveTo(folder: String, messageIds: [String], userId: String) -> [Message]? {
        var updatedMessages: [Message]?
        
        self.mainContext.performAndWaitWith { ctx in
            guard let messages = self.getMessages(ids: messageIds, context: ctx) else { return }
            
            for message in messages {
                let didMove: Bool = self.moveTo(folder: folder, message: message, userId: userId, context: ctx)
                
                guard didMove else { continue }
                
                updatedMessages = updatedMessages ?? []
                updatedMessages?.append(message)
            }
            
            if let error = ctx.saveUpstreamIfNeeded() {
                PMLog.D(error.localizedDescription)
                updatedMessages = nil
            } else {
                self.notifyConversationCountsUpdate(userId: userId)
            }
        }
        
        return updatedMessages
    }
    
    func updateUnread(messageIds: [String], unread: Bool, userId: String) -> [Message]? {
        var updatedMessages: [Message]?
        
        self.mainContext.performAndWaitWith { ctx in
            guard let messages = self.getMessages(ids: messageIds, context: ctx) else { return }
            
            for message in messages {
                guard message.unRead != unread else { continue }
                
                message.unRead = unread
                
                // Update number of unread message on the message's conversation
                self.updateUnreadCountOnConversation(forMessage: message, unread: unread)
                
                self.updateCounter(markUnRead: unread, on: message, userId: userId, context: ctx)
                
                // Track only messages that have their status changed
                updatedMessages = updatedMessages ?? []
                updatedMessages?.append(message)
            }
            
            if let error = ctx.saveUpstreamIfNeeded() {
                PMLog.D(error.localizedDescription)
                updatedMessages = nil
            } else {
                self.notifyConversationCountsUpdate(userId: userId)
            }
        }
        
        return updatedMessages
    }
    
    func getMessageIds(forURIRepresentations ids: [String]) -> [String]? {
        var messages: [String]?
        
        self.mainContext.performAndWaitWith { ctx in
            messages = ids.compactMap { (id: String) -> String? in
                if let objectID = self.managedObjectIDForURIRepresentation(id),
                   let managedObject = try? ctx.existingObject(with: objectID),
                   let message = managedObject as? Message
                {
                    return message.messageID
                }
                return nil
            }
        }
        
        return messages
    }
    
    func saveBody(messageId: String, body: String, completion: @escaping (Bool) -> Void) {
        self.backgroundContext.performWith { ctx in
            if let message = self.loadMessage(id: messageId, context: ctx) {
                message.body = body
                
                let success: Bool
                
                if let error = ctx.saveUpstreamIfNeeded() {
                    PMLog.D("Error saving body: \(error)")
                    success = false
                } else {
                    success = true
                }
                
                DispatchQueue.main.async {
                    completion(success)
                }
            } else {
                DispatchQueue.main.async {
                    completion(false)
                }
            }
        }
    }
    
    func loadLabelStatus(messageIds: [String], labelIds: [String], completion: @escaping ([String: Main.ToolbarItem.MenuItem.StateValue]?) -> Void) {
        self.backgroundContext.performWith { ctx in
            guard let messages = self.getMessages(ids: messageIds, context: ctx) else {
                DispatchQueue.main.async {
                    completion(nil)
                }
                return
            }
            
            var state: [String: Main.ToolbarItem.MenuItem.StateValue] = [:]
            
            for message in messages {
                for labelId in labelIds {
                    let contains: Bool = message.contains(label: labelId)
                    if let currentState = state[labelId] {
                        if (currentState == .off && contains) || (currentState == .on && !contains) {
                            state[labelId] = .mixed
                        }
                    } else {
                        state[labelId] = contains ? .on : .off
                    }
                }
            }
            
            DispatchQueue.main.async {
                completion(state)
            }
        }
    }
    
    //
    // MARK: - Internal
    //
    
    @discardableResult
    func updateLabel(forMessage message: Message, labelId: String, userId: String, apply: Bool, context: NSManagedObjectContext) -> String? {
        let updatedLabel: String?
        
        if apply {
            updatedLabel = message.add(labelID: labelId)
            if let newLabel = updatedLabel {
                if message.unRead {
                    self.updateUnreadCounter(message: message, plus: true, with: newLabel, userId: userId, context: context)
                }
                self.updateTotalCounter(message: message, plus: true, with: newLabel, userId: userId, context: context)
            }
        } else {
            updatedLabel = message.remove(labelID: labelId)
            if let newLabel = updatedLabel {
                if message.unRead {
                    self.updateUnreadCounter(message: message, plus: false, with: newLabel, userId: userId, context: context)
                }
                self.updateTotalCounter(message: message, plus: false, with: newLabel, userId: userId, context: context)
            }
        }
        
        guard let newLabel = updatedLabel else { return nil }
        
        // Update label on the conversation as well
        self.updateLabelOnConversationIfNeeded(message: message, labelId: newLabel, apply: apply)
        
        return newLabel
    }
    
    /// Updates the `numUnread` counter on the conversation that the given message belongs to.
    /// - Parameters:
    ///   - message: The message that belongs to the conversation we want to update.
    ///   - unread: `true` if the message is to be marked as unread and the counter should be incremented, `false` otherwise.
    func updateUnreadCountOnConversation(forMessage message: Message, unread: Bool) {
        let offset: Int = unread ? 1 : -1
        let oldNumUnread: Int = message.conversation.numUnread.intValue
        let newNumUnread: Int = max(oldNumUnread + offset, 0)
        message.conversation.numUnread = NSNumber(integerLiteral: newNumUnread)
    }
    
    func updateCounter(markUnRead: Bool, on message: Message, userId: String, context: NSManagedObjectContext) {
        let offset: Int = markUnRead ? 1 : -1
        let labelIDs: [String] = message.getLabelIDs()
        let conversation: Conversation = message.conversation
        
        guard let messages = conversation.messages as? Set<Message> else { return }
        
        // Ids of labels where messages are used (instead of conversations)
        // Unread count for these labels should update without checking other messages in the same conversation
        let messageLabels: Set<String> = ["1", "2", "7", "8"]
        
        for labelID in labelIDs {
            // Check if this label shows conversations count (instead of messages)
            if !messageLabels.contains(labelID) {
                // Get number of other unread messages in this conversation with this label
                let hasOtherUnread: Bool = !messages.filter( { $0.messageID != message.messageID && $0.unRead && $0.contains(label: labelID) }).isEmpty
                
                // If there are still other unread messages in this conversation
                // then the unread counter for this label does not change
                if hasOtherUnread {
                    continue
                }
            }
            
            let unreadCount: Int = self.unreadCount(for: labelID, userId: userId, context: context)
            var count = unreadCount + offset
            if count < 0 {
                count = 0
            }
            self.updateUnreadCount(for: labelID, userId: userId, count: count, context: context)
        }
    }
    
    func deleteMessage(id: String, context: NSManagedObjectContext) {
        if let message = Message.messageForMessageID(id, inManagedObjectContext: context) {
            let labelObjs = message.mutableSetValue(forKey: "labels")
            labelObjs.removeAllObjects()
            message.setValue(labelObjs, forKey: "labels")
            context.delete(message)
        }
    }
    
    func loadMessage(id: String, context: NSManagedObjectContext) -> Message? {
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: Message.Attributes.entityName)
        request.predicate = NSPredicate(format: "%K == %@", Message.Attributes.messageID, id)
        
        return (try? context.fetch(request) as? [Message])?.first
    }
    
    func updateLabelOnConversationIfNeeded(message: Message, labelId: String, apply: Bool) {
        // Fail early, no need to trigger the logic on allMail label
        if labelId.isLabel(.allMail) { return }
        
        let conversation: Conversation = message.conversation
        
        guard let messages = conversation.messages as? Set<Message> else { return }
        
        if apply {
            // If at least one message truly has the label, make sure it is set on the conversation as well
            if messages.contains(where: { $0.contains(label: labelId) }), !conversation.contains(label: labelId) {
                conversation.add(labelID: labelId)
            }
        } else {
            // If none of the messages in the conversation has the label, remove it from the conversation as well
            if messages.filter({ $0.contains(label: labelId) }).isEmpty, conversation.contains(label: labelId) {
                conversation.remove(labelID: labelId)
            }
        }
    }
    
    func updateUnreadCounter(message: Message, plus: Bool, with labelID: String, userId: String, shouldSave: Bool) {
        let context: NSManagedObjectContext = self.mainContext
        let newCount: Int? = self.updateUnreadCounter(message: message, plus: plus, with: labelID, userId: userId, context: context)
        
        if shouldSave {
            let error = context.saveUpstreamIfNeeded()
            if error == nil {
                // Set app badge
                if let count = newCount, labelID.isLabel(.allMail) {
                    self.setAppBadge(count)
                }
            }
        }
    }
    
    @discardableResult
    func updateUnreadCounter(message: Message, plus: Bool, with labelID: String, userId: String, context: NSManagedObjectContext) -> Int? {
        let conversation: Conversation = message.conversation
        
        // Ids of labels where messages are used (instead of conversations)
        // Unread count for these labels should update without checking other messages in the same conversation
        let messageLabels: Set<String> = ["1", "2", "7", "8"]
        
        // Check if this label shows conversations count (instead of messages)
        if !messageLabels.contains(labelID), let messages = conversation.messages as? Set<Message> {
            // Get number of other unread messages in this conversation with this label
            let hasOtherUnread: Bool = !messages.filter( { $0.messageID != message.messageID && $0.unRead && $0.contains(label: labelID) }).isEmpty
            
            // If there are still other unread messages in this conversation
            // then the unread counter for this label does not change
            if hasOtherUnread {
                return nil
            }
        }
        
        let offset: Int = plus ? 1 : -1
        let unreadCount: Int = self.unreadCount(for: labelID, userId: userId, context: context)
        var count = unreadCount + offset
        if count < 0 {
            count = 0
        }
        self.updateUnreadCount(for: labelID, userId: userId, count: count, context: context)
        
        return count
    }
    
    func updateTotalCounter(message: Message, plus: Bool, with labelID: String, userId: String, shouldSave: Bool) {
        let context: NSManagedObjectContext = self.mainContext
        self.updateTotalCounter(message: message, plus: plus, with: labelID, userId: userId, context: context)
        
        if shouldSave {
            let _ = context.saveUpstreamIfNeeded()
        }
    }
    
    @discardableResult
    func updateTotalCounter(message: Message, plus: Bool, with labelID: String, userId: String, context: NSManagedObjectContext) -> Int? {
        let conversation: Conversation = message.conversation
        
        // Ids of labels where messages are used (instead of conversations)
        // Unread count for these labels should update without checking other messages in the same conversation
        let messageLabels: Set<String> = ["1", "2", "7", "8"]
        
        // Check if this label shows conversations count (instead of messages)
        if !messageLabels.contains(labelID), let messages = conversation.messages as? Set<Message> {
            // Get number of other messages in this conversation with this label
            let hasOtherMessages: Bool = !messages.filter( { $0.messageID != message.messageID && $0.contains(label: labelID) }).isEmpty
            
            // If there are still other messages in this conversation
            // then the total counter for this label does not change
            if hasOtherMessages {
                return nil
            }
        }
        
        let offset: Int = plus ? 1 : -1
        let totalCount: Int = self.getTotalCount(for: labelID, userId: userId, context: context)
        var count = totalCount + offset
        if count < 0 {
            count = 0
        }
        self.updateTotalCount(for: labelID, userId: userId, count: count, context: context)
        
        return count
    }
    
    /// Moves the given message to a new folder.
    /// - Parameters:
    ///   - folder: The folder ID to move the message to.
    ///   - message: The message to move.
    ///   - userId: User's id.
    ///   - context: CoreData context.
    /// - Returns: `true` if the message folder has been updated, `false` otherwise.
    @discardableResult
    func moveTo(folder: String, message: Message, userId: String, context: NSManagedObjectContext) -> Bool {
        // Remove current folder from the message
        if let label = message.getFirstValidFolder() {
            self.updateLabel(forMessage: message, labelId: label, userId: userId, apply: false, context: context)
        }
        
        // Add message to the new folder
        guard let addedFolder = message.add(labelID: folder) else { return false }
        
        // If moving to Trash or Spam, remove custom labels and star
        if addedFolder.isLabel(.trash) || addedFolder.isLabel(.spam) {
            var labelsToRemove: [String] = message.getNormalLabelIDs()
            labelsToRemove.append(MailboxSidebar.Item.starred.id)
            
            // allMail label will not be removed, but is required in the list to update counters
            labelsToRemove.append(MailboxSidebar.Item.allMail.id)
            
            // Mark messages read if moving to Trash
            let markRead: Bool = addedFolder.isLabel(.trash)
            
            self.removeLabels(labelsToRemove, message: message, markRead: markRead, userId: userId, context: context)
        }
        
        self.updateLabelOnConversationIfNeeded(message: message, labelId: addedFolder, apply: true)
        
        // Update unread counter
        if message.unRead {
            self.updateUnreadCounter(message: message, plus: true, with: addedFolder, userId: userId, context: context)
            
            if let id = message.selfSent(labelID: addedFolder) {
                self.updateUnreadCounter(message: message, plus: true, with: id, userId: userId, context: context)
            }
        }
        
        // Update total counter
        self.updateTotalCounter(message: message, plus: true, with: addedFolder, userId: userId, context: context)
        
        return true
    }
    
    //
    // MARK: - Private
    //
    
    private func parseMessages(_ jsonArray: [[String: Any]], context: NSManagedObjectContext) -> [Message]? {
        do {
            return try GRTJSONSerialization.objects(withEntityName: "Message", fromJSONArray: jsonArray, in: context) as? [Message]
        } catch {
            PMLog.D("error parsing messages \(error)")
            return nil
        }
    }
    
    private func getMessages(ids: [String], context: NSManagedObjectContext) -> [Message]? {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: Message.Attributes.entityName)
        fetchRequest.predicate = NSPredicate(format: "%K in %@", Message.Attributes.messageID, ids as NSArray)
        
        do {
            return try context.fetch(fetchRequest) as? [Message]
        } catch {
            PMLog.D(" error: \(error)")
            return nil
        }
    }
    
    private func getPredicate(forUser userId: String, labelId: String, time: Date?) -> NSPredicate {
        let predicate: NSPredicate = NSPredicate(format: "userID == %@ AND (ANY labels.labelID == %@)", userId, labelId)
        if let time = time {
            let timePredicate: NSPredicate = NSPredicate(format: "time < %@", time as NSDate)
            return NSCompoundPredicate(type: .and, subpredicates: [timePredicate, predicate])
        }
        return predicate
    }
    
    private func removeLabels(_ labels: [String], message: Message, markRead: Bool, userId: String, context: NSManagedObjectContext) {
        // If `markRead` is set to `true` and the message is unread,
        // the unread counter will be decremented as the message will
        // be set as read after the labels are removed
        let isUnread: Bool = message.unRead
        for label in labels {
            guard let lid = message.remove(labelID: label) else { continue }
            
            // Remove the label from the conversation as well if needed
            self.updateLabelOnConversationIfNeeded(message: message, labelId: lid, apply: false)
            
            // Update unread counter
            if isUnread {
                self.updateUnreadCounter(message: message, plus: false, with: lid, userId: userId, context: context)
                
                if let id = message.selfSent(labelID: lid) {
                    self.updateUnreadCounter(message: message, plus: false, with: id, userId: userId, context: context)
                }
            }
            
            // Update total counter
            self.updateTotalCounter(message: message, plus: false, with: lid, userId: userId, context: context)
        }
        
        if markRead && isUnread {
            // Update number of unread message on the message's conversation
            self.updateUnreadCountOnConversation(forMessage: message, unread: false)
            
            message.unRead = false
        }
    }
    
}
