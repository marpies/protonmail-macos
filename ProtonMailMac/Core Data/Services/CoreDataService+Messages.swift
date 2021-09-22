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
    
    func fetchMessages(forUser userId: String, labelId: String, olderThan time: Date?, completion: @escaping ([Message]) -> Void) {
        self.backgroundContext.performWith { ctx in
            let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Message")
            request.predicate = self.getPredicate(forUser: userId, labelId: labelId, time: time)
            request.sortDescriptors = [NSSortDescriptor(key: "time", ascending: false)]
            request.fetchLimit = 50
            
            do {
                if let messages = try ctx.fetch(request) as? [Message] {
                    DispatchQueue.main.async {
                        completion(messages)
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
                self.updateLabel(forMessage: message, labelId: label, userId: userId, apply: apply)
            }
            
            let error = ctx.saveUpstreamIfNeeded()
            if let error = error {
                PMLog.D(" error: \(error)")
            } else {
                updatedMessages = messages
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
                
                self.updateCounter(markUnRead: unread, on: message, userId: userId, context: ctx)
                
                // Track only messages that have their status changed
                updatedMessages = updatedMessages ?? []
                updatedMessages?.append(message)
            }
            
            if let error = ctx.saveUpstreamIfNeeded() {
                PMLog.D(error.localizedDescription)
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
    
    func updateLabel(forMessage message: Message, labelId: String, userId: String, apply: Bool) {
        if apply {
            if message.add(labelID: labelId) != nil && message.unRead {
                self.updateCounterSync(plus: true, with: labelId, userId: userId, shouldSave: false)
            }
        } else {
            if message.remove(labelID: labelId) != nil && message.unRead {
                self.updateCounterSync(plus: false, with: labelId, userId: userId, shouldSave: false)
            }
        }
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
    
    //
    // MARK: - Internal
    //
    
    func updateCounter(markUnRead: Bool, on message: Message, userId: String, context: NSManagedObjectContext) {
        let offset = markUnRead ? 1 : -1
        let labelIDs: [String] = message.getLabelIDs()
        
        for lID in labelIDs {
            let unreadCount: Int = self.unreadCount(for: lID, userId: userId, context: context)
            var count = unreadCount + offset
            if count < 0 {
                count = 0
            }
            self.updateUnreadCount(for: lID, userId: userId, count: count, context: context)
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
    
    //
    // MARK: - Private
    //
    
    private func updateCounterSync(plus: Bool, with labelID: String, userId: String, shouldSave: Bool) {
        let offset = plus ? 1 : -1
        let unreadCount: Int = self.unreadCount(for: labelID, userId: userId)
        var count = unreadCount + offset
        if count < 0 {
            count = 0
        }
        
        self.updateUnreadCount(for: labelID, userId: userId, count: count, shouldSave: shouldSave)
    }
    
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
    
}
