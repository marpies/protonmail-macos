//
//  Conversation+Helpers.swift
//  ProtonMailMac
//
//  Created by Marcel Piešťanský on 16.09.2021.
//  Copyright © 2021 marpies. All rights reserved.
//

import Foundation

public extension Conversation {
    
    enum Attributes {
        static let entityName: String = "Conversation"
        
        static let conversationID: String = "conversationID"
        static let numAttachments: String = "numAttachments"
        static let numMessages: String = "numMessages"
        static let numUnread: String = "numUnread"
        static let order: String = "order"
        static let senders: String = "senders"
        static let recipients: String = "recipients"
        static let subject: String = "subject"
        static let time: String = "time"
        static let userID: String = "userID"
        static let labels: String = "labels"
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
    
    
    /// Adds a label to the conversation.
    /// - Parameter labelID: The label ID to add.
    /// - Returns: `true` if the label has been added, `false` otherwise.
    @discardableResult
    func add(labelID: String) -> Bool {
        guard let context = self.managedObjectContext,
              let toLabel = Label.labelForLabelID(labelID, inManagedObjectContext: context) else { return false }
        
        let labelObjs = self.mutableSetValue(forKey: Attributes.labels)
        
        var existing = false
        for l in labelObjs {
            if let label = l as? Label {
                if label == toLabel {
                    existing = true
                    break
                }
            }
        }
        
        if !existing {
            labelObjs.add(toLabel)
        }
        
        self.setValue(labelObjs, forKey: Attributes.labels)
        
        return !existing
    }
    
    func add(labelID: String, toMessages messages: [Message]) {
        var outLabels: Set<String> = []
        
        for message in messages {
            if let id = message.add(labelID: labelID) {
                outLabels.insert(id)
            }
        }
        
        if !outLabels.isEmpty {
            for id in outLabels {
                self.add(labelID: id)
            }
        }
    }
    
    /// Removes a label from the conversation.
    /// - Parameter labelID: The label ID to remove.
    /// - Returns: `true` if the label has been removed, `false` otherwise.
    @discardableResult
    func remove(labelID: String) -> Bool {
        if labelID.isLabel(.allMail)  {
            return false
        }
        
        var didRemove: Bool = false
        if let _ = self.managedObjectContext {
            let labelObjs = self.mutableSetValue(forKey: Attributes.labels)
            for l in labelObjs {
                if let label = l as? Label {
                    // can't remove label 1, 2, 5
                    //case draft   = "1"
                    //case sent    = "2"
                    //case allmail = "5"
                    if label.labelID == MailboxSidebar.Item.draft.hiddenId ||
                        label.labelID == MailboxSidebar.Item.outbox.hiddenId ||
                        label.labelID == MailboxSidebar.Item.allMail.id {
                        continue
                    }
                    if label.labelID == labelID {
                        labelObjs.remove(label)
                        didRemove = true
                        break
                    }
                }
            }
            self.setValue(labelObjs, forKey: Attributes.labels)
        }
        return didRemove
    }
    
    func getValidFolders() -> [String]? {
        guard let labels = self.labels as? Set<Label> else { return nil }
        
        var out: [String]?
        
        for label in labels {
            if label.exclusive == true {
                out = out ?? []
                out?.append(label.labelID)
            }
            
            if !label.labelID.preg_match("(?!^\\d+$)^.+$") {
                if label.labelID != "1", label.labelID != "2", !label.labelID.isLabel(.starred), !label.labelID.isLabel(.allMail) {
                    out = out ?? []
                    out?.append(label.labelID)
                }
            }
        }
        
        return out
    }
    
    func getNormalLabelIDs() -> [String] {
        var labelIDs: [String] = []
        let labels = self.labels
        for l in labels {
            if let label = l as? Label, label.exclusive == false {
                if label.labelID.preg_match ("(?!^\\d+$)^.+$") {
                    labelIDs.append(label.labelID )
                }
            }
        }
        return labelIDs
    }
    
}
