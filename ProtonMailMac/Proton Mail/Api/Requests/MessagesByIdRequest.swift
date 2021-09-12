//
//  MessagesByIdRequest.swift
//  ProtonMailMac
//
//  Created by Marcel Piešťanský on 09.09.2021.
//  Copyright © 2021 marpies. All rights reserved.
//

import Foundation

struct MessagesByIDRequest : Request {
    
    var authCredential: AuthCredential?
    var path: String {
        return MessagesAPI.path + self.buildURL()
    }
    
    let msgIDs : [String]
    
    init(msgIDs: [String]) {
        self.msgIDs = msgIDs
    }
    
    internal func buildURL () -> String {
        var out = ""
        for msgID in self.msgIDs {
            if !out.isEmpty {
                out = out + "&"
            }
            out = out + "ID[]=\(msgID)"
        }
        if !out.isEmpty {
            out = "?" + out
        }
        return out
    }
    
    func copyWithCredential(_ credential: AuthCredential) -> MessagesByIDRequest {
        var copy: MessagesByIDRequest = self
        let newCredential: AuthCredential = copy.authCredential ?? credential
        newCredential.update(sessionID: credential.sessionID, accessToken: credential.accessToken, refreshToken: credential.refreshToken, expiration: credential.expiration)
        copy.authCredential = newCredential
        return copy
    }
}
