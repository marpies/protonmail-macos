//
//  LabelUpdateDatabaseManaging.swift
//  ProtonMailMac
//
//  Created by Marcel Piešťanský on 09.09.2021.
//  Copyright © 2021 marpies. All rights reserved.
//

import Foundation
import PromiseKit

protocol LabelUpdateDatabaseManaging {
    func removeUpdateTime(forUser userId: String)
    
    func lastUpdate(for labelId : String, userId: String) -> LabelUpdate?
    func lastUpdateDefault(for labelId : String, userId: String) -> LabelUpdate
    func unreadCount(for labelId : String, userId: String) -> Promise<Int>
    func unreadCount(for labelId : String, userId: String) -> Int
    func getTotalCount(for labelId : String, userId: String) -> Int
    func updateCount(for labelId: String, userId: String, unread: Int, total: Int, shouldSave: Bool)
    func updateCounts(userId: String, counts: [LabelMessageCount])
    func updateUnreadCount(for labelId : String, userId: String, count: Int, shouldSave: Bool)
}
