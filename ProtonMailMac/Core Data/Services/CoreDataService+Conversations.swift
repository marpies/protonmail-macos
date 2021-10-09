//
//  CoreDataService+Conversations.swift
//  ProtonMailMac
//
//  Created by Marcel Piešťanský on 16.09.2021.
//  Copyright © 2021 marpies. All rights reserved.
//

import Foundation
import CoreData
import Groot
import PromiseKit

extension CoreDataService: ConversationsDatabaseManaging {
    
    func saveConversations(_ json: [[String : Any]], forUser userId: String, completion: @escaping () -> Void) {
        self.backgroundContext.performWith { ctx in
            guard let conversations = self.parseConversations(json, context: ctx) else {
                DispatchQueue.main.async {
                    completion()
                }
                return
            }
            
            if let error = ctx.saveUpstreamIfNeeded() {
                PMLog.D("Error saving conversations \(error)")
            } else {
                PMLog.D("Success saving conversations")
            }
            
            DispatchQueue.main.async {
                completion()
            }
        }
    }
    
    func loadConversation(id: String) -> Conversation? {
        var conversation: Conversation?
        
        self.mainContext.performAndWaitWith { ctx in
            let request = NSFetchRequest<NSFetchRequestResult>(entityName: Conversation.Attributes.entityName)
            request.predicate = NSPredicate(format: "%K == %@", Conversation.Attributes.conversationID, id)
            
            conversation = (try? ctx.fetch(request) as? [Conversation])?.first
        }
        
        return conversation
    }
    
    func fetchConversations(forUser userId: String, labelId: String, converter: ConversationToModelConverting, completion: @escaping ([Conversations.Conversation.Response]) -> Void) {
        self.backgroundContext.performWith { ctx in
            let request = NSFetchRequest<NSFetchRequestResult>(entityName: Conversation.Attributes.entityName)
            request.predicate = self.getPredicate(forUser: userId, labelId: labelId)
            request.sortDescriptors = [NSSortDescriptor(key: "time", ascending: false)]
            request.fetchLimit = 50
            
            do {
                if let conversations = try ctx.fetch(request) as? [Conversation] {
                    let models: [Conversations.Conversation.Response] = conversations.map { converter.getConversation($0) }
                    DispatchQueue.main.async {
                        completion(models)
                    }
                    return
                }
            } catch {
                PMLog.D("Error fetching conversations \(error)")
            }
            
            DispatchQueue.main.async {
                completion([])
            }
        }
    }
    
    func cleanConversations(forUser userId: String, removeDrafts: Bool) -> Promise<Void> {
        return Promise { seal in
            self.enqueue(context: self.backgroundContext) { (context) in
                let request = NSFetchRequest<NSFetchRequestResult>(entityName: Conversation.Attributes.entityName)
                request.predicate = NSPredicate(format: "%K == %@", Conversation.Attributes.userID, userId)
                
                if removeDrafts {
                    if let conversations = try? context.fetch(request) as? [Conversation] {
                        for conversation in conversations {
                            if let messages = self.getMessagesForConversationId(conversation.conversationID, context: context) {
                                messages.forEach { context.delete($0) }
                            }
                            context.delete(conversation)
                        }
                        _ = context.saveUpstreamIfNeeded()
                    }
                    
                    self.setAppBadge(0)
                } else {
                    let draftID: String = MailboxSidebar.Item.draft.id
                    
                    if let conversations = try? context.fetch(request) as? [Conversation] {
                        for conversation in conversations {
                            guard let messages = self.getMessagesForConversationId(conversation.conversationID, context: context) else { continue }
                            
                            for message in messages {
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
                                
                                context.delete(message)
                            }
                            
                            context.delete(conversation)
                        }
                    }
                    
                    _ = context.saveUpstreamIfNeeded()
                }
                
                seal.fulfill_()
            }
        }
    }
    
    func deleteConversation(id: String) {
        self.deleteConversations(ids: [id])
    }
    
    func deleteConversations(ids: [String]) {
        self.enqueue(context: self.mainContext) { ctx in
            self.deleteConversations(ids: ids, context: ctx)
        }
    }
    
    func updateLabel(conversationIds: [String], label: String, apply: Bool, includingMessages: Bool, userId: String) -> [Conversation]? {
        var updatedConversations: [Conversation]?
        
        self.mainContext.performAndWaitWith { ctx in
            guard let conversations = self.getConversations(ids: conversationIds, context: ctx) else { return }
            
            for conversation in conversations {
                // Update label on all the messages in the conversation
                if includingMessages,
                   let messages = self.getMessagesForConversationId(conversation.conversationID, context: ctx),
                   !messages.isEmpty {
                    let labelObjs = conversation.mutableSetValue(forKey: Conversation.Attributes.labels)
                    
                    labelObjs.removeAllObjects()
                    
                    for message in messages {
                        self.updateLabel(forMessage: message, labelId: label, userId: userId, apply: apply)
                        
                        for label in message.labels {
                            labelObjs.add(label)
                        }
                    }
                    
                    conversation.setValue(labelObjs, forKey: Conversation.Attributes.labels)
                }
                
                if apply {
                    conversation.add(labelID: label)
                } else {
                    conversation.remove(labelID: label)
                }
            }
            
            let error = ctx.saveUpstreamIfNeeded()
            if let error = error {
                PMLog.D(" error: \(error)")
            } else {
                updatedConversations = conversations
                
                self.notifyUnreadCountersUpdate(userId: userId)
            }
        }
        
        return updatedConversations
    }
    
    func updateUnread(conversationIds: [String], unread: Bool, userId: String) -> [Conversation]? {
        var updatedConversations: [Conversation]?
        
        self.mainContext.performAndWaitWith { ctx in
            guard let conversations = self.getConversations(ids: conversationIds, context: ctx) else { return }
            
            for conversation in conversations {
                var numUnread: Int = 0
                
                // Update status on all messages in the conversation
                if let messages = conversation.messages as? Set<Message> {
                    for message in messages {
                        if message.unRead != unread {
                            message.unRead = unread
                            
                            self.updateCounter(markUnRead: unread, on: message, userId: userId, context: ctx)
                        }
                        
                        if message.unRead {
                            numUnread += 1
                        }
                    }
                }
                
                // If messages are not downloaded, still mark the conversation as unread
                if unread && numUnread == 0 {
                    numUnread = 1
                }
                
                conversation.numUnread = NSNumber(integerLiteral: numUnread)
            }
            
            let error = ctx.saveUpstreamIfNeeded()
            if let error = error {
                PMLog.D(" error: \(error)")
            } else {
                updatedConversations = conversations
                
                self.notifyUnreadCountersUpdate(userId: userId)
            }
        }
        
        return updatedConversations
    }
    
    func getConversationIds(forURIRepresentations ids: [String]) -> [String]? {
        var result: [String]?
        
        self.mainContext.performAndWaitWith { ctx in
            result = ids.compactMap { (id: String) -> String? in
                if let objectID = self.managedObjectIDForURIRepresentation(id),
                   let managedObject = try? ctx.existingObject(with: objectID),
                   let message = managedObject as? Conversation
                {
                    return message.conversationID
                }
                return nil
            }
        }
        
        return result
    }
    
    //
    // MARK: - Internal
    //
    
    func deleteConversation(id: String, context: NSManagedObjectContext) {
        self.deleteConversations(ids: [id], context: context)
    }
    
    func deleteConversations(ids: [String], context: NSManagedObjectContext) {
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: Conversation.Attributes.entityName)
        request.predicate = NSPredicate(format: "%K IN %@", Conversation.Attributes.conversationID, ids as NSArray)
        
        if let conversations = try? context.fetch(request) as? [Conversation] {
            for conversation in conversations {
                guard let messages = self.getMessagesForConversationId(conversation.conversationID, context: context) else { continue }
                
                for message in messages {
                    let labelObjs = message.mutableSetValue(forKey: Message.Attributes.labels)
                    labelObjs.removeAllObjects()
                    message.setValue(labelObjs, forKey: Message.Attributes.labels)
                    context.delete(message)
                }
                
                let labelObjs = conversation.mutableSetValue(forKey: Message.Attributes.labels)
                labelObjs.removeAllObjects()
                conversation.setValue(labelObjs, forKey: Message.Attributes.labels)
                context.delete(conversation)
            }
        }
        
        if let error = context.saveUpstreamIfNeeded() {
            PMLog.D("error: \(error)")
        }
    }
    
    //
    // MARK: - Private
    //
    
    private func getMessagesForConversationId(_ conversationId: String, context: NSManagedObjectContext) -> [Message]? {
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: Message.Attributes.entityName)
        request.predicate = NSPredicate(format: "conversation.conversationID == %@", conversationId)
        
        return try? context.fetch(request) as? [Message]
    }
    
    private func parseConversations(_ jsonArray: [[String: Any]], context: NSManagedObjectContext) -> [Conversation]? {
        do {
            return try GRTJSONSerialization.objects(withEntityName: "Conversation", fromJSONArray: jsonArray, in: context) as? [Conversation]
        } catch {
            PMLog.D("error parsing conversations \(error)")
            return nil
        }
    }
    
    private func getConversations(ids: [String], context: NSManagedObjectContext) -> [Conversation]? {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: Conversation.Attributes.entityName)
        fetchRequest.predicate = NSPredicate(format: "%K IN %@", Conversation.Attributes.conversationID, ids as NSArray)
        
        do {
            return try context.fetch(fetchRequest) as? [Conversation]
        } catch {
            PMLog.D(" error: \(error)")
            return nil
        }
    }
    
    private func getPredicate(forUser userId: String, labelId: String) -> NSPredicate {
        return NSPredicate(format: "userID == %@ AND (ANY labels.labelID == %@)", userId, labelId)
    }
    
}
