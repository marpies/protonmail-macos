//
//  File.swift
//  
//
//  Created by Marcel Piešťanský on 22.08.2021.
//

import Foundation

public struct AuthResponse: Codable, CredentialConvertible {
    public struct TwoFA: Codable {
        public var enabled: State
        
        public enum State: Int, Codable {
            case off, on, u2f, otp
        }
    }
    
    public var code: Int
    public var accessToken: String
    public var expiresIn: TimeInterval
    public var tokenType: String
    public var refreshToken: String
    public var scope: Scope
    public var UID: String
    public var userID: String
    public var eventID: String
    public var serverProof: String
    public var passwordMode: PasswordMode
    
    public var _2FA: TwoFA
}
