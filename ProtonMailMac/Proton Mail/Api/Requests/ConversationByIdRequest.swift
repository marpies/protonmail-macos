//
//  ConversationByIdRequest.swift
//  ProtonMailMac
//
//  Created by Marcel Piešťanský on 17.09.2021.
//  Copyright © 2021 marpies. All rights reserved.
//

import Foundation

struct ConversationByIdRequest: Request {
    
    let isAuth: Bool = true
    let conversationId: String
    
    var authCredential: AuthCredential?
    
    var path: String {
        return ConversationsAPI.path + "/" + self.conversationId
    }
    
    init(conversationId: String) {
        self.conversationId = conversationId
    }
    
}
