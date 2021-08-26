//
//  File.swift
//  
//
//  Created by Marcel Piešťanský on 22.08.2021.
//

import Foundation

public final class MessageDetailResponse: Response {
    
    public private(set) var messageId: String?
    public private(set) var body: String?
    public private(set) var messageJson: [String: Any]?
    
    override public func parseResponse(_ response: [String : Any]) -> Bool {
        if let messageJson = response["Message"] as? [String: Any] {
            self.messageId = messageJson["ID"] as? String
            self.body = messageJson["Body"] as? String
            self.messageJson = messageJson
        }
        return true
    }
}
