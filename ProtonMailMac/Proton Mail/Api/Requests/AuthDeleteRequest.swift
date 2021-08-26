//
//  AuthDeleteRequest.swift
//  ProtonMailMac
//
//  Created by Marcel Piešťanský on 23.08.2021.
//

import Foundation

public struct AuthDeleteRequest: Request {
    
    public let path: String = AuthAPI.path
    
    public let method: HTTPMethod = .delete
    
    public let isAuth: Bool = true
    
    public let autoRetry: Bool = false
    
    public private(set) var authCredential: AuthCredential?
    
    public func copyWithCredential(_ credential: AuthCredential) -> AuthDeleteRequest {
        var copy: AuthDeleteRequest = self
        let newCredential: AuthCredential = copy.authCredential ?? credential
        newCredential.update(sessionID: credential.sessionID, accessToken: credential.accessToken, refreshToken: credential.refreshToken, expiration: credential.expiration)
        copy.authCredential = newCredential
        return copy
    }
    
}
