//
//  UserEventsDatabaseProcessing.swift
//  ProtonMailMac
//
//  Created by Marcel Piešťanský on 09.09.2021.
//  Copyright © 2021 marpies. All rights reserved.
//

import Foundation
import PromiseKit

protocol UserEventsDatabaseProcessing {
    func process(conversations: [[String: Any]]?, messages: [[String : Any]]?, userId: String, completion: @escaping ([String], NSError?) -> Void)
    
    func processEvents(addresses: [[String : Any]]?, userId: String) -> Promise<Void>
    func processEvents(labels: [[String : Any]]?, userId: String) -> Promise<Void>
    func processEvents(contactEmails: [[String : Any]]?, userId: String) -> Promise<Void>
    func processEvents(contacts: [[String : Any]]?, userId: String) -> Promise<Void>
    func processEvents(counts: [[String : Any]]?, userId: String)
}
