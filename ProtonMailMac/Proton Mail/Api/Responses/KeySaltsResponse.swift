//
//  File.swift
//  
//
//  Created by Marcel Piešťanský on 22.08.2021.
//

import Foundation

public final class KeySaltResponse: Response {
    public private(set) var keySalt: String?
    public private(set) var keyID: String?
    
    override public func parseResponse(_ response: [String : Any]) -> Bool {
        if let keySalts = response["KeySalts"] as? [[String : Any]],
           let firstKeySalt = keySalts.first {
            self.keySalt = firstKeySalt["KeySalt"] as? String
            self.keyID = firstKeySalt["ID"] as? String
        }
        return true
    }
}
