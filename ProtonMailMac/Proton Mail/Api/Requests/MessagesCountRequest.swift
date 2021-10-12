//
//  MessagesCountRequest.swift
//  ProtonMailMac
//
//  Created by Marcel Piešťanský on 11.10.2021.
//  Copyright © 2021 marpies. All rights reserved.
//

import Foundation

struct MessagesCountRequest: Request {
    
    var authCredential: AuthCredential?
    
    let path: String = MessagesAPI.path + "/count"
    
    init() { }
    
}
