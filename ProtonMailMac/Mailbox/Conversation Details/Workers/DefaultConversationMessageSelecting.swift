//
//  DefaultConversationMessageSelecting.swift
//  ProtonMailMac
//
//  Created by Marcel Piešťanský on 05.10.2021.
//  Copyright © 2021 marpies. All rights reserved.
//

import Foundation

protocol DefaultConversationMessageSelecting {
    /// Returns the message that should be expanded when a conversation is loaded.
    /// May return `nil` if there is no message to be expanded, e.g. when conversation contains drafts only.
    func getDefaultMessage(conversation: ConversationDetails.Conversation.Response) -> Messages.Message.Response?
}

extension DefaultConversationMessageSelecting {
    
    func getDefaultMessage(conversation: ConversationDetails.Conversation.Response) -> Messages.Message.Response? {
        // Find the first unread message
        if let message = conversation.messages.first(where: { $0.isRead == false && $0.isDraft == false }) {
            return message
        }
        
        // No unread messages, get the last message that is not a draft
        if let message = conversation.messages.last(where: { $0.isDraft == false }) {
            return message
        }
        
        // Conversation contains drafts only?
        return nil
    }
    
}
