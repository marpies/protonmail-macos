//
//  File.swift
//  
//
//  Created by Marcel Piešťanský on 22.08.2021.
//

import Foundation

public struct KeySaltsRequest: Request {
    public var authCredential : AuthCredential?
    
    public init(authCredential: AuthCredential) {
        self.authCredential = authCredential
    }
    
    public var path: String {
        return KeysAPI.path + "/salts"
    }
    
    public let isAuth: Bool = true
    
}
