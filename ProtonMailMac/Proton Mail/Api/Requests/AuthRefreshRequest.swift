//
//  AuthRefreshRequest.swift
//  ProtonMailMac
//
//  Created by Marcel Piešťanský on 23.08.2021.
//

import Foundation

public struct AuthRefreshRequest: Request {
    
    public let authCredential: AuthCredential?
    public let refreshToken: String
    
    public let path: String = AuthAPI.path + "/refresh"
    public let method: HTTPMethod = .post
    public let isAuth: Bool = true
    
    public var parameters: [String: Any]? {
        let body = [
            "ResponseType": "token",
            "GrantType": "refresh_token",
            "RefreshToken": self.refreshToken,
            "RedirectURI": "http://protonmail.ch"
        ]
        return body
    }
    
    init(authCredential: AuthCredential) {
        self.authCredential = authCredential
        self.refreshToken = authCredential.refreshToken
    }
}
