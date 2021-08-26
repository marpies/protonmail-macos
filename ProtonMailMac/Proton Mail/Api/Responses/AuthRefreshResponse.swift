//
//  AuthRefreshResponse.swift
//  ProtonMailMac
//
//  Created by Marcel Piešťanský on 23.08.2021.
//

import Foundation

public struct AuthRefreshResponse: Codable, CredentialConvertible {
    
    public var code: Int
    public var accessToken: String
    public var expiresIn: TimeInterval
    public var tokenType: String
    public var scope: AuthResponse.Scope
    public var refreshToken: String

    public init(code: Int, accessToken: String, expiresIn: TimeInterval, tokenType: String, scope: AuthResponse.Scope, refreshToken: String) {
        self.code = code
        self.accessToken = accessToken
        self.expiresIn = expiresIn
        self.tokenType = tokenType
        self.scope = scope
        self.refreshToken = refreshToken
    }
    
}
