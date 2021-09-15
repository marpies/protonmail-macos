//
//  MessageActionRequest.swift
//  ProtonMailMac
//
//
//  Copyright (c) 2019 Proton Technologies AG
//
//  This file is part of ProtonMail.
//
//  ProtonMail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ProtonMail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonMail.  If not, see <https://www.gnu.org/licenses/>.
//

import Foundation

struct MessageActionRequest : Request {
    let messages : [Message]
    let action : String
    var ids : [String] = [String] ()
    var authCredential: AuthCredential?
    
    private var currentLabelID: Int? = nil
    
    init(action: String, messages: [Message]) {
        self.messages = messages
        self.action = action
        for message in messages {
            if message.isDetailDownloaded {
                ids.append(message.messageID)
            }
        }
    }
    
    init(action: String, ids: [String], labelID: String? = nil) {
        self.action = action
        self.ids = ids
        self.messages = [Message]()
        
        if let num = Int(labelID ?? "") {
            self.currentLabelID = num
        }
    }
    
    var parameters: [String : Any]? {
        var out: [String: Any] = ["IDs" : self.ids]
        if let id = self.currentLabelID {
            out["CurrentLabelID"] = id
        }
        return out
    }
    
    var path: String {
        return MessagesAPI.path + "/" + self.action
    }
    
    var method: HTTPMethod {
        return .put
    }
}
