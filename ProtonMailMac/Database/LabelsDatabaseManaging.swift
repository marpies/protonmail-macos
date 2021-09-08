//
//  LabelsDatabaseManaging.swift
//  ProtonMailMac
//
//  Created by Marcel Piešťanský on 29.08.2021.
//  Copyright © 2021 marpies. All rights reserved.
//

import Foundation

enum LabelFetchType : Int {
    case all = 0
    case label = 1
    case folder = 2
    case contactGroup = 3
    case folderWithInbox = 4
    case folderWithOutbox = 5
}

protocol LabelsDatabaseManaging {
    func saveLabels(_ json: [[String: Any]], forUser userId: String, completion: @escaping ([Label]) -> Void)
    func fetchLabels(ofType type: LabelFetchType, forUser userId: String, completion: @escaping ([Label]) -> Void)
    func deleteLabelsById(_ ids: Set<String>, completion: (() -> Void)?)
}
