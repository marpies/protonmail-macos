//
//  Message+Helpers.swift
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

extension Message {
    
    enum Attributes {
        static let entityName = "Message"
        static let isDetailDownloaded = "isDetailDownloaded"
        static let messageID = "messageID"
        static let conversationID = "conversationID"
        static let toList = "toList"
        static let sender = "sender"
        static let time = "time"
        static let title = "title"
        static let labels = "labels"
        
        static let messageType = "messageType"
        static let messageStatus = "messageStatus"
        
        static let expirationTime = "expirationTime"
        
        // 1.9.1
        static let unRead = "unRead"
        
        // 1.12.0
        static let userID = "userID"
        
        // 1.12.9
        static let isSending = "isSending"
    }
    
    class func messageForMessageID(_ messageID: String, inManagedObjectContext context: NSManagedObjectContext) -> Message? {
        return context.managedObjectWithEntityName(Attributes.entityName, forKey: Attributes.messageID, matchingValue: messageID) as? Message
    }
    
    /// check if contains exclusive lable
    ///
    /// - Parameter label: Location
    /// - Returns: yes or no
    internal func contains(label: MailboxSidebar.Item) -> Bool {
        return self.contains(label: label.id)
    }
    
    /// check if contains the lable
    ///
    /// - Parameter labelID: label id
    /// - Returns: yes or no
    internal func contains(label labelID: String) -> Bool {
        let labels = self.labels
        for l in labels {
            if let label = l as? Label, labelID == label.labelID {
                return true
            }
        }
        return false
    }
    
    func checkLabels() {
        guard let labels = self.labels.allObjects as? [Label] else {return}
        let labelIDs = labels.map {$0.labelID}
        guard labelIDs.contains(MailboxSidebar.Item.draft.id) else {
            return
        }
        
        // This is the basic labes for draft
        let basic = [MailboxSidebar.Item.draft.id,
                     MailboxSidebar.Item.allMail.id,
                     MailboxSidebar.Item.draft.hiddenId]
        for label in labels {
            let id = label.labelID
            if basic.contains(id) {continue}
            
            if let _ = Int(id) {
                // default folder
                // The draft can't in the draft folder and another folder at the same time
                // the draft folder label should be removed
                self.remove(labelID: MailboxSidebar.Item.draft.id)
                break
            }
            
            // In v3 api, exclusive == true means folder
            guard label.exclusive else {continue}
            
            self.remove(labelID: MailboxSidebar.Item.draft.id)
            break
        }
    }
    
    @discardableResult
    func add(labelID: String) -> String? {
        var outLabel: String?
        //1, 2, labels can't be in inbox,
        var addLabelID = labelID
        if labelID == MailboxSidebar.Item.inbox.id && (self.contains(label: MailboxSidebar.Item.draft.hiddenId) || self.contains(label: MailboxSidebar.Item.draft.id)) {
            // move message to 1 / 8
            addLabelID = MailboxSidebar.Item.draft.id //"8"
        }
        
        if labelID == MailboxSidebar.Item.inbox.id && (self.contains(label: MailboxSidebar.Item.outbox.hiddenId) || self.contains(label: MailboxSidebar.Item.outbox.id)) {
            // move message to 2 / 7
            addLabelID = sentSelf ? MailboxSidebar.Item.inbox.id : MailboxSidebar.Item.outbox.id //"7"
        }
        
        if let context = self.managedObjectContext {
            let labelObjs = self.mutableSetValue(forKey: Attributes.labels)
            if let toLabel = Label.labelForLabelID(addLabelID, inManagedObjectContext: context) {
                var exsited = false
                for l in labelObjs {
                    if let label = l as? Label {
                        if label == toLabel {
                            exsited = true
                            break
                        }
                    }
                }
                if !exsited {
                    outLabel = addLabelID
                    labelObjs.add(toLabel)
                }
            }
            self.setValue(labelObjs, forKey: Attributes.labels)
            
        }
        return outLabel
    }
    
    @discardableResult
    func remove(labelID: String) -> String? {
        if MailboxSidebar.Item.allMail.id == labelID  {
            return MailboxSidebar.Item.allMail.id
        }
        var outLabel: String?
        if let _ = self.managedObjectContext {
            let labelObjs = self.mutableSetValue(forKey: Attributes.labels)
            for l in labelObjs {
                if let label = l as? Label {
                    // can't remove label 1, 2, 5
                    //case inbox   = "0"
                    //case draft   = "1"
                    //case sent    = "2"
                    //case starred = "10"
                    //case archive = "6"
                    //case spam    = "4"
                    //case trash   = "3"
                    //case allmail = "5"
                    if label.labelID == MailboxSidebar.Item.draft.hiddenId ||
                        label.labelID == MailboxSidebar.Item.outbox.hiddenId ||
                        label.labelID == MailboxSidebar.Item.allMail.id {
                        continue
                    }
                    if label.labelID == labelID {
                        labelObjs.remove(label)
                        outLabel = labelID
                        break
                    }
                }
            }
            self.setValue(labelObjs, forKey: "labels")
        }
        return outLabel
    }
    
}
