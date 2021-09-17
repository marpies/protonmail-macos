//
//  CoreDataService+UserEvents.swift
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
//

import Foundation
import CoreData
import Groot
import PromiseKit

extension CoreDataService: UserEventsDatabaseManaging {
    
    func getLastEventId(forUser userId: String) -> String {
        var eventId: String?
        self.backgroundContext.performAndWait {
            eventId = self.getEvent(forUser: userId, context: self.backgroundContext).eventID
        }
        return eventId ?? ""
    }
    
    func updateEventId(forUser userId: String, eventId: String, completion: (() -> Void)?) {
        self.backgroundContext.performWith { ctx in
            let event = self.getEvent(forUser: userId, context: ctx)
            event.eventID = eventId
            let _ = ctx.saveUpstreamIfNeeded()
            
            DispatchQueue.main.async {
                completion?()
            }
        }
    }
    
    //
    // MARK: - Private
    //
    
    private func getEvent(forUser userID: String, context: NSManagedObjectContext) -> UserEvent {
        if let update = UserEvent.userEvent(by: userID,
                                            inManagedObjectContext: context) {
            return update
        }
        return UserEvent.newUserEvent(userID: userID,
                                      inManagedObjectContext: context)
    }
    
}

extension CoreDataService: UserEventsDatabaseProcessing {
    
    func process(conversations: [[String: Any]], messages: [[String : Any]], userId: String, completion: @escaping ([String], NSError?) -> Void) {
        let context: NSManagedObjectContext = self.mainContext
        self.enqueue(context: context) { (ctx) in
            // List of message ids for which there is no metadata
            var (messagesNoCache, responseError): ([String], NSError?) = self.processMessageEvents(messages, userId: userId, context: ctx)
            
            let conversationsError: NSError? = self.processConversationEvents(conversations, userId: userId, context: ctx)
            
            if let error = ctx.saveUpstreamIfNeeded() {
                PMLog.D(" error: \(error)")
                responseError = error
            }
            
            DispatchQueue.main.async {
                completion(messagesNoCache, responseError ?? conversationsError)
            }
        }
    }
    
    func processEvents(labels: [[String : Any]]?, userId: String) -> Promise<Void> {
        enum IncrementalUpdateType {
            static let delete = 0
            static let insert = 1
            static let update = 2
        }
        
        guard let labels = labels else {
            return Promise()
        }
        
        return Promise { seal in
            let context: NSManagedObjectContext = self.mainContext
            self.enqueue(context: context) { (context) in
                for labelEvent in labels {
                    let label = LabelEvent(event: labelEvent)
                    switch label.Action {
                    case .some(IncrementalUpdateType.delete):
                        if let labelID = label.ID {
                            if let dLabel = Label.labelForLabelID(labelID, inManagedObjectContext: context) {
                                context.delete(dLabel)
                            }
                        }
                    case .some(IncrementalUpdateType.insert), .some(IncrementalUpdateType.update):
                        do {
                            if var new_or_update_label = label.label {
                                new_or_update_label["UserID"] = userId
                                try GRTJSONSerialization.object(withEntityName: Label.Attributes.entityName, fromJSONDictionary: new_or_update_label, in: context)
                            }
                        } catch let ex as NSError {
                            PMLog.D(" error: \(ex)")
                        }
                    default:
                        PMLog.D(" unknown type in message: \(label)")
                    }
                }
                
                if let error = context.saveUpstreamIfNeeded(){
                    PMLog.D(" error: \(error)")
                }
                
                seal.fulfill_()
            }
        }
    }
    
    func processEvents(addresses: [[String : Any]]?, userId: String) -> Promise<Void> {
        guard let addrEvents = addresses else {
            return Promise()
        }
        
        return Promise { seal in
            // todo process addresses
            seal.fulfill_()
        }
    }
    
    func processEvents(contacts: [[String : Any]]?, userId: String) -> Promise<Void> {
        guard let contacts = contacts else {
            return Promise()
        }
        
        return Promise { seal in
            let context: NSManagedObjectContext = self.mainContext
            self.enqueue(context: context) { (context) in
                defer {
                    seal.fulfill_()
                }
                for contact in contacts {
                    let contactObj = ContactEvent(event: contact)
                    switch(contactObj.action) {
                    case .delete:
                        if let contactID = contactObj.ID {
                            if let tempContact = Contact.contactForContactID(contactID, inManagedObjectContext: context) {
                                context.delete(tempContact)
                            }
                        }
                        //save it earily
                        if let error = context.saveUpstreamIfNeeded()  {
                            PMLog.D(" error: \(error)")
                        }
                    case .insert, .update:
                        do {
                            if let outContacts = try GRTJSONSerialization.objects(withEntityName: Contact.Attributes.entityName,
                                                                                  fromJSONArray: contactObj.contacts,
                                                                                  in: context) as? [Contact] {
                                for c in outContacts {
                                    c.isDownloaded = false
                                    c.userID = userId
                                    if let emails = c.emails.allObjects as? [Email] {
                                        emails.forEach { (e) in
                                            e.userID = userId
                                        }
                                    }
                                }
                            }
                        } catch let ex as NSError {
                            PMLog.D(" error: \(ex)")
                        }
                        if let error = context.saveUpstreamIfNeeded() {
                            PMLog.D(" error: \(error)")
                        }
                    default:
                        PMLog.D(" unknown type in contact: \(contact)")
                    }
                }
            }
        }
    }
    
    func processEvents(contactEmails: [[String : Any]]?, userId: String) -> Promise<Void> {
        guard let emails = contactEmails else {
            return Promise()
        }
        
        return Promise { seal in
            let context: NSManagedObjectContext = self.mainContext
            self.enqueue(context: context) { (context) in
                defer {
                    seal.fulfill_()
                }
                for email in emails {
                    let emailObj = EmailEvent(event: email)
                    switch(emailObj.action) {
                    case .delete:
                        if let emailID = emailObj.ID {
                            if let tempEmail = Email.EmailForID(emailID, inManagedObjectContext: context) {
                                context.delete(tempEmail)
                            }
                        }
                    case .insert, .update:
                        do {
                            if let outContacts = try GRTJSONSerialization.objects(withEntityName: Contact.Attributes.entityName,
                                                                                  fromJSONArray: emailObj.contacts,
                                                                                  in: context) as? [Contact] {
                                for c in outContacts {
                                    c.isDownloaded = false
                                    c.userID = userId
                                    if let emails = c.emails.allObjects as? [Email] {
                                        emails.forEach { (e) in
                                            e.userID = userId
                                        }
                                    }
                                }
                            }
                            
                        } catch let ex as NSError {
                            PMLog.D(" error: \(ex)")
                        }
                    default:
                        PMLog.D(" unknown type in contact: \(email)")
                    }
                }
                
                if let error = context.saveUpstreamIfNeeded()  {
                    PMLog.D(" error: \(error)")
                }
            }
        }
    }
    
    func processEvents(counts: [[String : Any]]?, userId: String) {
        guard let messageCounts = counts, messageCounts.count > 0 else {
            return
        }
        
        let context: NSManagedObjectContext = self.mainContext
        self.enqueue(context: context) { (context) in
            for count in messageCounts {
                if let labelID = count["LabelID"] as? String {
                    guard let unread = count["Unread"] as? Int else {
                        continue
                    }
                    self.updateUnreadCount(for: labelID, userId: userId, count: unread, shouldSave: false)
                }
            }
            
            if let error = context.saveUpstreamIfNeeded() {
                PMLog.D(error.localizedDescription)
            }
            
            let unreadCount: Int = self.unreadCount(for: MailboxSidebar.Item.inbox.id, userId: userId)
            var badgeNumber = unreadCount
            if  badgeNumber < 0 {
                badgeNumber = 0
            }
            self.setAppBadge(badgeNumber)
        }
    }
    
    //
    // MARK: - Private
    //
    
    private func processConversationEvents(_ conversations: [[String: Any]], userId: String, context: NSManagedObjectContext) -> NSError? {
        enum IncrementalUpdateType {
            static let delete = 0
            static let insert = 1
            static let update1 = 2
            static let update2 = 3
        }
        
        var responseError: NSError?
        
        for event in conversations {
            let conversation: ConversationEvent = ConversationEvent(event: event)
            
            switch conversation.Action {
            case .some(IncrementalUpdateType.delete):
                if let id = conversation.ID {
                    self.deleteConversation(id: id, context: context)
                }
                
            case .some(IncrementalUpdateType.insert), .some(IncrementalUpdateType.update1), .some(IncrementalUpdateType.update2):
                guard let json = conversation.conversation else { continue }
                
                do {
                    if let conversationObject = try GRTJSONSerialization.object(withEntityName: Conversation.Attributes.entityName, fromJSONDictionary: json, in: context) as? Conversation {
                        conversationObject.userID = userId
                        
                        // apply the label changes
                        if let deleted = json["LabelIDsRemoved"] as? [String] {
                            for labelId in deleted {
                                guard let label = Label.labelForLabelID(labelId, inManagedObjectContext: context) else { continue }
                                
                                let labelObjs = conversationObject.mutableSetValue(forKey: "labels")
                                if labelObjs.count > 0 {
                                    labelObjs.remove(label)
                                    conversationObject.setValue(labelObjs, forKey: "labels")
                                }
                            }
                        }
                        
                        if let added = json["LabelIDsAdded"] as? [String] {
                            for labelId in added {
                                guard let label = Label.labelForLabelID(labelId, inManagedObjectContext: context) else { continue }
                                
                                let labelObjs = conversationObject.mutableSetValue(forKey: "labels")
                                labelObjs.add(label)
                                conversationObject.setValue(labelObjs, forKey: "labels")
                            }
                        }
                        
                        if conversationObject.managedObjectContext != nil {
                            if let error = context.saveUpstreamIfNeeded() {
                                PMLog.D(" error: \(error)")
                                responseError = error
                            }
                        }
                    }
                } catch {
                    #if DEBUG
                    let status: String
                    
                    switch conversation.Action {
                    case IncrementalUpdateType.update1:
                        status = "Update1"
                    case IncrementalUpdateType.update2:
                        status = "Update2"
                    case IncrementalUpdateType.insert:
                        status = "Insert"
                    case IncrementalUpdateType.delete:
                        status = "Delete"
                    default:
                        status = "Other: \(String(describing: conversation.Action))"
                    }
                    
                    PMLog.D(" error with msg status \(status): \(error)")
                    #endif
                }
                
            default:
                PMLog.D(" unknown action in conversation: \(event)")
            }
        }
        
        return responseError
    }
    
    private func processMessageEvents(_ messages: [[String: Any]], userId: String, context: NSManagedObjectContext) -> (noCacheIds: [String], error: NSError?) {
        enum IncrementalUpdateType {
            static let delete = 0
            static let insert = 1
            static let update1 = 2
            static let update2 = 3
        }
        
        var messagesNoCache: [String] = []
        var responseError: NSError?
        
        for message in messages {
            let msg = MessageEvent(event: message)
            switch(msg.Action) {
            case .some(IncrementalUpdateType.delete):
                if let messageID = msg.ID {
                    self.deleteMessage(id: messageID, context: context)
                }
            case .some(IncrementalUpdateType.insert), .some(IncrementalUpdateType.update1), .some(IncrementalUpdateType.update2):
                if IncrementalUpdateType.insert == msg.Action {
                    if let id = msg.ID, let cachedMessage = Message.messageForMessageID(id, inManagedObjectContext: context) {
                        if !cachedMessage.contains(label: .outbox) {
                            continue
                        }
                    }
                    msg.message?["messageStatus"] = 1
                }
                
                let isMessageDraft: Bool = self.isMessageDraft(msg)
                if isMessageDraft,
                   let id = msg.ID,
                   let existingMsg = Message.messageForMessageID(id, inManagedObjectContext: context),
                   existingMsg.messageStatus == 1 {
                    if let subject = msg.message?["Subject"] as? String {
                        existingMsg.title = subject
                    }
                    if let timeValue = msg.message?["Time"] {
                        if let timeString = timeValue as? NSString {
                            let time = timeString.doubleValue as TimeInterval
                            if time != 0 {
                                existingMsg.time = time.asDate()
                            }
                        } else if let dateNumber = timeValue as? NSNumber {
                            let time = dateNumber.doubleValue as TimeInterval
                            if time != 0 {
                                existingMsg.time = time.asDate()
                            }
                        }
                    }
                    continue
                }
                
                do {
                    if let messageObject = try GRTJSONSerialization.object(withEntityName: Message.Attributes.entityName, fromJSONDictionary: msg.message ?? [String : Any](), in: context) as? Message {
                        // apply the label changes
                        if let deleted = msg.message?["LabelIDsRemoved"] as? [String] {
                            for labelId in deleted {
                                if let label = Label.labelForLabelID(labelId, inManagedObjectContext: context) {
                                    let labelObjs = messageObject.mutableSetValue(forKey: "labels")
                                    if labelObjs.count > 0 {
                                        labelObjs.remove(label)
                                        messageObject.setValue(labelObjs, forKey: "labels")
                                    }
                                }
                            }
                        }
                        
                        messageObject.userID = userId
                        if msg.Action == IncrementalUpdateType.update1 {
                            messageObject.isDetailDownloaded = false
                        }
                        
                        
                        if let added = msg.message?["LabelIDsAdded"] as? [String] {
                            for labelId in added {
                                if let label = Label.labelForLabelID(labelId, inManagedObjectContext: context) {
                                    let labelObjs = messageObject.mutableSetValue(forKey: "labels")
                                    labelObjs.add(label)
                                    messageObject.setValue(labelObjs, forKey: "labels")
                                }
                            }
                        }
                        
                        if msg.message?["LabelIDs"] != nil {
                            messageObject.checkLabels()
                        }
                        
                        // Check if we have metadata
                        if messageObject.messageStatus == 0 {
                            if messageObject.title.isEmpty {
                                messagesNoCache.append(messageObject.messageID)
                            } else {
                                messageObject.messageStatus = 1
                            }
                        }
                        
                        if messageObject.managedObjectContext != nil {
                            if let error = context.saveUpstreamIfNeeded() {
                                if let messageid = msg.message?["ID"] as? String {
                                    messagesNoCache.append(messageid)
                                }
                                PMLog.D(" error: \(error)")
                                responseError = error
                            }
                        } else {
                            if let messageid = msg.message?["ID"] as? String {
                                messagesNoCache.append(messageid)
                            }
                            PMLog.D(" GRTJSONSerialization Insert - context nil")
                        }
                    } else {
                        // when GRTJSONSerialization inset returns no thing
                        if let messageid = msg.message?["ID"] as? String {
                            messagesNoCache.append(messageid)
                        }
                        PMLog.D(" case .Some(IncrementalUpdateType.insert), .Some(IncrementalUpdateType.update1), .Some(IncrementalUpdateType.update2): insert empty")
                    }
                } catch let err as NSError {
                    // when GRTJSONSerialization insert failed
                    if let messageid = msg.message?["ID"] as? String {
                        messagesNoCache.append(messageid)
                    }
                    
                    #if DEBUG
                    let status: String
                    
                    switch msg.Action {
                    case IncrementalUpdateType.update1:
                        status = "Update1"
                    case IncrementalUpdateType.update2:
                        status = "Update2"
                    case IncrementalUpdateType.insert:
                        status = "Insert"
                    case IncrementalUpdateType.delete:
                        status = "Delete"
                    default:
                        status = "Other: \(String(describing: msg.Action))"
                    }
                    
                    PMLog.D(" error with msg status \(status): \(err)")
                    #endif
                }
            default:
                PMLog.D(" unknown type in message: \(message)")
            }
        }
        
        return (messagesNoCache, responseError)
    }
    
    private func isMessageDraft(_ event: MessageEvent) -> Bool {
        guard let json = event.message else { return false }
        
        let location: Int = (json["Location"] as? Int) ?? -1
        if location == 1 || location == 8 {
            return true
        }
        
        if let labelIDs = json["LabelIDs"] as? [String] {
            return labelIDs.contains("1") || labelIDs.contains("8")
        }
        
        return false
    }
    
}
