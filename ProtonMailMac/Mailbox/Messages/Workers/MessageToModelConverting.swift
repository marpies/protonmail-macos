//
//  MessageToModelConverting.swift
//  ProtonMailMac
//
//  Created by Marcel Piešťanský on 10.09.2021.
//  Copyright © 2021 marpies. All rights reserved.
//

import Foundation
import AppKit

protocol MessageToModelConverting {
    var labelId: String { get }
    
    func getMessage(_ message: Message) -> Messages.Message.Response
}

extension MessageToModelConverting {
    
    func getMessage(_ message: Message) -> Messages.Message.Response {
        let sender: String = self.getSender(message)
        let timeRaw: Date = message.time ?? Date()
        let time: Messages.MessageTime = self.getMessageTime(timeRaw)
        let isStarred: Bool = self.isMessageStarred(message)
        let folders: [Messages.Folder.Response]? = self.getFolders(message)
        let labels: [Messages.Label.Response]? = self.getLabels(message)
        let isRepliedTo: Bool = message.flag.contains(.replied) || message.flag.contains(.repliedAll)
        let body: String? = message.body.isEmpty ? nil : message.body
        let isDraft: Bool = message.contains(label: .draft)
        let metadata: Messages.Message.Metadata.Response = self.getMetadata(message)
        return Messages.Message.Response(id: message.messageID, subject: message.title, senderName: sender, time: time, isStarred: isStarred, isRepliedTo: isRepliedTo, numAttachments: message.numAttachments.intValue, isRead: !message.unRead, isDraft: isDraft, metadata: metadata, folders: folders, labels: labels, body: body, isExpanded: false)
    }
    
    //
    // MARK: - Private
    //
    
    private func getMetadata(_ message: Message) -> Messages.Message.Metadata.Response {
        return Messages.Message.Metadata.Response(isEndToEndEncrypted: message.isE2E, isInternal: message.isInternal, isExternal: message.isExternal, isPgpInline: message.isPgpInline, isPgpMime: message.isPgpMime, isSignedMime: message.isSignedMime, isPlainText: message.isPlainText, isMultipartMixed: message.isMultipartMixed)
    }
    
    private func getMessageTime(_ messageDate: Date) -> Messages.MessageTime {
        let today: Date = Calendar.current.startOfDay(for: Date())
        if messageDate > today {
            return .today(messageDate)
        }
        
        if let yesterday: Date = Calendar.current.date(byAdding: .hour, value: -24, to: today), messageDate > yesterday {
            return .yesterday(messageDate)
        }
        
        return .other(messageDate)
    }
    
    private func getSender(_ message: Message) -> String {
        if let jsonRaw = message.sender, let json = jsonRaw.parseObjectAny() {
            return json.getString("Name") ?? json.getString("Address") ?? ""
        }
        return ""
    }
    
    private func isMessageStarred(_ message: Message) -> Bool {
        if let labels = message.labels as? Set<Label> {
            let starredId: String = MailboxSidebar.Item.starred.id
            return labels.contains { label in
                return label.labelID == starredId
            }
        }
        return false
    }
    
    private func getFolders(_ message: Message) -> [Messages.Folder.Response]? {
        // Return folders only when browsing the "all mail" folder
        guard self.labelId == MailboxSidebar.Item.allMail.id else { return nil }
        
        guard var labels = message.labels.allObjects as? [Label] else { return nil }
        
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
    
    private func getLabels(_ message: Message) -> [Messages.Label.Response]? {
        guard var labels = message.labels.allObjects as? [Label] else { return nil }
        
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
