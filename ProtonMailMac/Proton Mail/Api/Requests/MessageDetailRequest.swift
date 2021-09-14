//
//  File.swift
//  
//
//  Created by Marcel Piešťanský on 22.08.2021.
//

import Foundation

public struct MessageDetailRequest: Request {
    public var authCredential : AuthCredential?
    public let messageId: String
    
    public init(messageId: String, authCredential: AuthCredential) {
        self.messageId = messageId
        self.authCredential = authCredential
    }
    
    public var path: String {
        return MessagesAPI.path + "/\(self.messageId)"
    }
    
    public let isAuth: Bool = true
    
}
