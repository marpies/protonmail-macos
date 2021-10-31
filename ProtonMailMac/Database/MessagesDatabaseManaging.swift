//
//  MessagesDatabaseManaging.swift
//  ProtonMailMac
//
//  Created by Marcel Piešťanský on 06.09.2021.
//  Copyright © 2021 marpies. All rights reserved.
//

import Foundation
import PromiseKit

protocol MessagesDatabaseManaging {
    func saveBody(messageId: String, body: String, completion: @escaping (Bool) -> Void)
    func saveMessages(_ json: [[String: Any]], forUser userId: String, completion: @escaping () -> Void)
    func loadMessage(id: String) -> Message?
    func fetchMessages(forUser userId: String, labelId: String, converter: MessageToModelConverting, completion: @escaping ([Messages.Message.Response]) -> Void)
    func cleanMessages(forUser userId: String, removeDrafts: Bool) -> Promise<Void>
    func deleteMessage(id: String)
    func deleteMessages(ids: [String])
    func updateLabel(messageIds: [String], label: String, apply: Bool, userId: String) -> [Message]?
    func updateUnread(messageIds: [String], unread: Bool, userId: String) -> [Message]?
    func getMessageIds(forURIRepresentations ids: [String]) -> [String]?
    func moveTo(folder: String, messageIds: [String], userId: String) -> [Message]?
    
    /// Loads the label "status" for the given messages and labels.
    /// If all messages have a given label, the status is `on`.
    /// If no messages have a given label, the status is `off`.
    /// If some messages do and some messages do NOT have a given label, the status is `mixed`.
    /// This is used to determine the state value of menu items in `NSToolbar`.
    /// - Parameters:
    ///   - messageIds: The ids of the messages to check.
    ///   - labelIds: The ids of the labels to check.
    ///   - completion: Callback with a map of label ids to their status.
    func loadLabelStatus(messageIds: [String], labelIds: [String], completion: @escaping ([String: Main.ToolbarItem.Menu.Item.StateValue]?) -> Void)
}
