//
//  File.swift
//  
//
//  Created by Marcel Piešťanský on 22.08.2021.
//

import Foundation

public struct AuthRequest: Request {
    public var authCredential: AuthCredential?
    
    public let username: String
    public let ephemeral: Data
    public let proof: Data
    public let session: String
    
    public init(username: String,
                ephemeral: Data,
                proof: Data,
                session: String) {
        self.username = username
        self.ephemeral = ephemeral
        self.proof = proof
        self.session = session
    }
    
    public let path: String = AuthAPI.path
    
    public let method: HTTPMethod = .post
    
    public var parameters: [String: Any]? {
        return [
            "Username": username,
            "ClientEphemeral": ephemeral.base64EncodedString(),
            "ClientProof": proof.base64EncodedString(),
            "SRPSession": session
        ]
    }
    public let isAuth: Bool = false
    
}
