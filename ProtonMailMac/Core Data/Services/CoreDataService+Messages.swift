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
    
    private func getPredicate(forUser userId: String, labelId: String, time: Date?) -> NSPredicate {
        let predicate: NSPredicate = NSPredicate(format: "userID == %@ AND (ANY labels.labelID == %@)", userId, labelId)
        if let time = time {
            let timePredicate: NSPredicate = NSPredicate(format: "time < %@", time as NSDate)
            return NSCompoundPredicate(type: .and, subpredicates: [timePredicate, predicate])
        }
        return predicate
    }
    
}