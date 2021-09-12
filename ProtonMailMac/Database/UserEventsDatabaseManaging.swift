//
//  UserEventsDatabaseManaging.swift
//  ProtonMailMac
//
//  Created by Marcel Piešťanský on 08.09.2021.
//  Copyright © 2021 marpies. All rights reserved.
//

import Foundation

protocol UserEventsDatabaseManaging {
    func getLastEventId(forUser userId: String) -> String
    func updateEventId(forUser userId: String, eventId: String, completion: (() -> Void)?)
}
