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
    
    /// Updates label on the given conversations and their messages.
    /// - Parameters:
    ///   - conversationIds: Ids of the conversations to update.
    ///   - label: The label to add or remove.
    ///   - apply: `true` if the label should be added.
    ///   - userId: User's id.
    func updateLabel(conversationIds: [String], label: String, apply: Bool, userId: String) -> [Conversation]?
    
    func moveTo(folder: String, conversationIds: [String], userId: String) -> [Conversation]?
    
    /// Loads the label "status" for the given conversations and labels.
    /// If all conversations have a given label, the status is `on`.
    /// If no conversations have a given label, the status is `off`.
    /// If some conversations do and some conversations do NOT have a given label, the status is `mixed`.
    /// This is used to determine the state value of menu items in `NSToolbar`.
    /// - Parameters:
    ///   - conversationIds: The ids of the conversations to check.
    ///   - labelIds: The ids of the labels to check.
    ///   - completion: Callback with a map of label ids to their status.
    func loadLabelStatus(conversationIds: [String], labelIds: [String], completion: @escaping ([String: Main.ToolbarItem.Menu.Item.StateValue]?) -> Void)
}
