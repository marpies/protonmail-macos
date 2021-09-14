//
//  File.swift
//  
//
//  Created by Marcel Piešťanský on 22.08.2021.
//

import Foundation

public struct AuthInfoRequest: Request {
    struct Key {
        static let userName = "Username"
    }
    
    public let username: String
    
    public init(username: String) {
        self.username = username
    }
    
    public let path: String = "auth/info"
    
    public let method: HTTPMethod = .post
    
    public var parameters: [String: Any]? {
        return [Key.userName: self.username]
    }
    
    public let isAuth: Bool = false
    
    public var authCredential: AuthCredential?
}
