//
//  ApplyLabelToConversationsRequest.swift
//  ProtonMailMac
//
//  Created by Marcel Piešťanský on 21.09.2021.
//  Copyright © 2021 marpies. All rights reserved.
//

import Foundation

struct ApplyLabelToConversationsRequest: Request {
    
    let labelID: String
    let conversationIds:[String]
    
    var authCredential: AuthCredential?
    
    init(labelID: String, conversationIds: [String]) {
        self.labelID = labelID
        self.conversationIds = conversationIds
    }
    
    var parameters: [String : Any]? {
        var out : [String : Any] = [String : Any]()
        out["LabelID"] = self.labelID
        out["IDs"] = self.conversationIds
        return out
    }
    
    var path: String {
        return ConversationsAPI.path + "/label"
    }
    
    var method: HTTPMethod {
        return .put
    }
    
}
