//
//  File.swift
//  
//
//  Created by Marcel Piešťanský on 22.08.2021.
//

import Foundation

public final class AuthInfoResponse: Response {
    public var modulus: String?
    public var serverEphemeral: String?
    public var version: Int = 0
    public var salt: String?
    public var srpSession: String?
    
    override public func parseResponse(_ response: [String: Any]) -> Bool {
        self.modulus = response["Modulus"] as? String
        self.serverEphemeral = response["ServerEphemeral"] as? String
        self.version = response["Version"] as? Int ?? 0
        self.salt = response["Salt"] as? String
        self.srpSession = response["SRPSession"] as? String
        return true
    }
}
