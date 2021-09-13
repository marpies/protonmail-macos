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
    func saveMessages(_ json: [[String: Any]], forUser userId: String, completion: @escaping () -> Void)
    func fetchMessages(forUser userId: String, labelId: String, olderThan time: Date?, completion: @escaping ([Message]) -> Void)
    func cleanMessages(forUser userId: String, removeDrafts: Bool) -> Promise<Void>
}