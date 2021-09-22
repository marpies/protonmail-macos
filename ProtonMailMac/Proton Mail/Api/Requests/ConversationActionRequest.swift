//
//  ConversationActionRequest.swift
//  ProtonMailMac
//
//  Created by Marcel Piešťanský on 21.09.2021.
//  Copyright © 2021 marpies. All rights reserved.
//

import Foundation

struct ConversationActionRequest: Request {
    let action: String
    let ids: [String]
    
    var authCredential: AuthCredential?
    
    init(action: String, ids: [String]) {
        self.action = action
        self.ids = ids
    }
    
    var parameters: [String : Any]? {
        return ["IDs" : self.ids]
    }
    
    var path: String {
        return ConversationsAPI.path + "/" + self.action
    }
    
    var method: HTTPMethod {
        return .put
    }
}
