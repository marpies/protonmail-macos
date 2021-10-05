//
//  ConversationToModelConverting.swift
//  ProtonMailMac
//
//  Created by Marcel Piešťanský on 16.09.2021.
//  Copyright © 2021 marpies. All rights reserved.
//

import Foundation
import AppKit

protocol ConversationToModelConverting {
    var labelId: String { get }
    
    func getConversation(_ conversation: Conversation) -> Conversations.Conversation.Response
}

extension ConversationToModelConverting {
    
    func getConversation(_ conversation: Conversation) -> Conversations.Conversation.Response {
        let senders: [String] = self.getSenders(conversation)
        let timeRaw: Date = conversation.time ?? Date()
        let time: Messages.MessageTime = self.getConversationTime(timeRaw)
        let isStarred: Bool = self.isMessageStarred(conversation)
        let folders: [Messages.Folder.Response]? = self.getFolders(conversation)
        let labels: [Messages.Label.Response]? = self.getLabels(conversation)
        return Conversations.Conversation.Response(id: conversation.conversationID, subject: conversation.subject, senderNames: senders, time: time, numMessages: conversation.numMessages.intValue, numAttachments: conversation.numAttachments.intValue, isRead: conversation.numUnread == 0, isStarred: isStarred, folders: folders, labels: labels)
    }
    
    //
    // MARK: - Private
    //
    
    private func getConversationTime(_ messageDate: Date) -> Messages.MessageTime {
        let today: Date = Calendar.current.startOfDay(for: Date())
        if messageDate > today {
            return .today(messageDate)
        }
        
        if let yesterday: Date = Calendar.current.date(byAdding: .hour, value: -24, to: today), messageDate > yesterday {
            return .yesterday(messageDate)
        }
        
        return .other(messageDate)
    }
    
    private func getSenders(_ conversation: Conversation) -> [String] {
        if let json = conversation.senders?.parseJsonArray() {
            var senders: [String] = []
            for sender in json {
                let name: String
                if let senderName = sender.getString("Name"), !senderName.isEmpty {
                    name = senderName
                } else {
                    name = sender.getString("Address") ?? ""
                }
                senders.append(name)
            }
            return senders
        }
        return []
    }
    
    private func isMessageStarred(_ conversation: Conversation) -> Bool {
        if let labels = conversation.labels as? Set<Label> {
            let starredId: String = MailboxSidebar.Item.starred.id
            return labels.contains { label in
                return label.labelID == starredId
            }
        }
        return false
    }
    
    private func getFolders(_ conversation: Conversation) -> [Messages.Folder.Response]? {
        // Return folders only when browsing the "all mail" folder
        guard self.labelId == MailboxSidebar.Item.allMail.id else { return nil }
        
        guard var labels = conversation.labels.allObjects as? [Label] else { return nil }
        
        labels.sort { l1, l2 in
            return l1.order.compare(l2.order) == .orderedAscending
        }
        
        var result: [Messages.Folder.Response]?
        
        for label in labels {
            guard !self.isHiddenFolder(id: label.labelID) &&
                    (label.exclusive || label.name.isEmpty) else { continue }
            
            var color: NSColor?
            if !label.color.isEmpty {
                color = NSColor(hexColorCode: label.color)
            }
            
            let name: String? = label.name.isEmpty ? nil : label.name
            let kind: Messages.Folder = Messages.Folder(id: label.labelID, title: name)
            let model: Messages.Folder.Response = Messages.Folder.Response(kind: kind, color: color)
            
            result = result ?? []
            result?.append(model)
        }
        
        return result
    }
    
    private func isHiddenFolder(id: String) -> Bool {
        let hiddenOutboxId: String = MailboxSidebar.Item.outbox.hiddenId
        let hiddenDraftsId: String = MailboxSidebar.Item.draft.hiddenId
        let allMailId: String = MailboxSidebar.Item.allMail.id
        let starredId: String = MailboxSidebar.Item.starred.id
        return (id == allMailId) || (id == starredId) || (id == hiddenOutboxId) || (id == hiddenDraftsId)
    }
    
    private func getLabels(_ conversation: Conversation) -> [Messages.Label.Response]? {
        guard var labels = conversation.labels.allObjects as? [Label] else { return nil }
        
        labels.sort { l1, l2 in
            return l1.order.compare(l2.order) == .orderedAscending
        }
        
        var result: [Messages.Label.Response]?
        
        for label in labels {
            guard !label.exclusive, !label.name.isEmpty, !label.color.isEmpty else { continue }
            
            let color: NSColor = NSColor(hexColorCode: label.color)
            let model: Messages.Label.Response = Messages.Label.Response(id: label.labelID, title: label.name, color: color)
            
            result = result ?? []
            result?.append(model)
        }
        
        return result
    }
    
}
