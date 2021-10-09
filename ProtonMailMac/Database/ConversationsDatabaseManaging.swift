//
//  ConversationsDatabaseManaging.swift
//  ProtonMailMac
//
//  Created by Marcel Piešťanský on 16.09.2021.
//  Copyright © 2021 marpies. All rights reserved.
//

import Foundation
import PromiseKit

protocol ConversationsDatabaseManaging {
    func saveConversations(_ json: [[String: Any]], forUser userId: String, completion: @escaping () -> Void)
    func loadConversation(id: String) -> Conversation?
    func fetchConversations(forUser userId: String, labelId: String, converter: ConversationToModelConverting, completion: @escaping ([Conversations.Conversation.Response]) -> Void)
    func cleanConversations(forUser userId: String, removeDrafts: Bool) -> Promise<Void>
    func deleteConversation(id: String)
    func deleteConversations(ids: [String])
    func updateUnread(conversationIds: [String], unread: Bool, userId: String) -> [Conversation]?
    func getConversationIds(forURIRepresentations ids: [String]) -> [String]?
    
    /// Updates label on the given conversations.
    /// - Parameters:
    ///   - conversationIds: Ids of the conversations to update.
    ///   - label: The label to add or remove.
    ///   - apply: `true` if the label should be added.
    ///   - includingMessages: `true` if the label should be updated on all the messages in the conversation as well.
    ///   - userId: User's id.
    func updateLabel(conversationIds: [String], label: String, apply: Bool, includingMessages: Bool, userId: String) -> [Conversation]?
}
