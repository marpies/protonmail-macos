//
//  ConversationLabelStatusChecking.swift
//  ProtonMailMac
//
//  Created by Marcel Piešťanský on 12.10.2021.
//  Copyright © 2021 marpies. All rights reserved.
//

import Foundation

protocol ConversationLabelStatusChecking {
    /// Checks if a conversation was updated after a label change occurred to one of its messages.
    /// When a message label is updated, the update may also affect the conversation.
    /// This method posts a notification if a change on the conversation also occurred,
    /// allowing scenes to update the conversation view as necessary.
    /// - Parameters:
    ///   - label: The label to check.
    ///   - conversation: The conversation id to check.
    ///   - hasLabel: `true` if the conversation had the label *before* the message was updated. The actual labels on the
    ///               conversation object are updated together with the message, therefore this has to be provided.
    func checkConversationLabel(label: MailboxSidebar.Item, conversation: Conversation, hasLabel: Bool)
}

extension ConversationLabelStatusChecking {
    
    func checkConversationLabel(label: MailboxSidebar.Item, conversation: Conversation, hasLabel: Bool) {
        guard let messages = conversation.messages as? Set<Message> else { return }
        
        // Check if any of the message in the conversation has the label
        var shouldHaveLabel: Bool = false
        for message in messages {
            if message.contains(label: label) {
                shouldHaveLabel = true
                break
            }
        }
        
        // If the label status changed on the conversation, dispatch notification
        if (hasLabel && !shouldHaveLabel) || (!hasLabel && shouldHaveLabel) {
            // Dispatch notification for other sections (e.g. list of conversations)
            // This worker will react to this notification as well
            let notification: Conversations.Notifications.ConversationUpdate = Conversations.Notifications.ConversationUpdate(conversationId: conversation.conversationID)
            notification.post()
        }
    }
    
}
