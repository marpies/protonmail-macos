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
    func fetchMessages(forUser userId: String, labelId: String, olderThan time: Date?, converter: MessageToModelConverting, completion: @escaping ([Messages.Message.Response]) -> Void)
    func cleanMessages(forUser userId: String, removeDrafts: Bool) -> Promise<Void>
    func deleteMessage(id: String)
    func deleteMessages(ids: [String])
    func updateLabel(messageIds: [String], label: String, apply: Bool, userId: String) -> [Message]?
    func updateUnread(messageIds: [String], unread: Bool, userId: String) -> [Message]?
    func getMessageIds(forURIRepresentations ids: [String]) -> [String]?
}
