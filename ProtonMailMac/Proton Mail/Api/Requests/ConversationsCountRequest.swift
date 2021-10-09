//
//  ConversationsCountRequest.swift
//  ProtonMailMac
//
//  Created by Marcel Piešťanský on 09.10.2021.
//  Copyright © 2021 marpies. All rights reserved.
//

import Foundation

struct ConversationsCountRequest: Request {
    
    var authCredential: AuthCredential?
    
    let path: String = ConversationsAPI.path + "/count"
    
    init() { }
    
}
