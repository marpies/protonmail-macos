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
    func fetchConversations(forUser userId: String, labelId: String, completion: @escaping ([Conversation]) -> Void)
    func cleanConversations(forUser userId: String, removeDrafts: Bool) -> Promise<Void>
    func deleteConversation(id: String)
    func deleteConversations(ids: [String])
    func updateLabel(conversationIds: [String], label: String, apply: Bool, userId: String) -> [Conversation]?
    func updateUnread(conversationIds: [String], unread: Bool, userId: String) -> [Conversation]?
    func getConversationIds(forURIRepresentations ids: [String]) -> [String]?
}
