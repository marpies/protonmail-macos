//
//  MessagesByLabelRequest.swift
//  ProtonMailMac
//
//  Created by Marcel Piešťanský on 06.09.2021.
//  Copyright © 2021 marpies. All rights reserved.
//

import Foundation

struct MessagesByLabelRequest: Request {
    let path: String = MessagesAPI.path
    let isAuth: Bool = true
    
    let labelID: String
    let endTime: TimeInterval
    
    var authCredential: AuthCredential?
    
    var parameters: [String : Any]? {
        var out: [String : Any] = ["Sort" : "Time"]
        out["LabelID"] = self.labelID
        if self.endTime > 0 {
            let newTime = self.endTime - 1
            out["End"] = newTime
        }
        return out
    }
    
    init(labelID: String, endTime: TimeInterval = 0) {
        self.labelID = labelID
        self.endTime = endTime
    }
    
    func copyWithCredential(_ credential: AuthCredential) -> MessagesByLabelRequest {
        var copy: MessagesByLabelRequest = self
        let newCredential: AuthCredential = copy.authCredential ?? credential
        newCredential.update(sessionID: credential.sessionID, accessToken: credential.accessToken, refreshToken: credential.refreshToken, expiration: credential.expiration)
        copy.authCredential = newCredential
        return copy
    }
}
