//
//  ConversationsRequest.swift
//  ProtonMailMac
//
//  Created by Marcel Piešťanský on 16.09.2021.
//  Copyright © 2021 marpies. All rights reserved.
//

import Foundation

enum ConversationsSort: String {
    case time = "Time"
    case size = "Size"
}

struct ConversationsRequest: Request {
    
    let path: String = ConversationsAPI.path
    let isAuth: Bool = true
    
    let labelID: String
    let page: Int
    let sort: ConversationsSort
    let descendingSort: Bool
    
    var authCredential: AuthCredential?
    
    var parameters: [String : Any]? {
        return [
            "Sort": self.sort.rawValue,
            "LabelID": self.labelID,
            "Desc": self.descendingSort ? 1 : 0,
            "Page": self.page,
            "PageSize": 50,
            "Limit": 100
        ]
    }
    
    init(labelID: String, page: Int = 0, sort: ConversationsSort = .time, descendingSort: Bool = true) {
        self.labelID = labelID
        self.page = page
        self.sort = sort
        self.descendingSort = descendingSort
    }
    
}
