//
//  ConversationsCountResponse.swift
//  ProtonMailMac
//
//  Created by Marcel Piešťanský on 09.10.2021.
//  Copyright © 2021 marpies. All rights reserved.
//

import Foundation

final class ConversationsCountResponse: Response {
    
    struct ConversationCount {
        let labelId: String
        let total: Int
        let unread: Int
    }
    
    private(set) var conversationCounts: [ConversationCount]?
    
    override func parseResponse(_ response: [String : Any]) -> Bool {
        if let counts = response["Counts"] as? [[String: Any]] {
            self.conversationCounts = []
            
            // Skip outbox/draft labels for conversations, we use message counts for those
            let skipIds: Set<String> = ["1", "2", "7", "8"]
            
            for json in counts {
                guard let labelId = json.getString("LabelID"),
                      !skipIds.contains(labelId),
                      let total = json.getInt("Total"),
                      let unread = json.getInt("Unread") else { continue }
                
                let count: ConversationCount = ConversationCount(labelId: labelId, total: total, unread: unread)
                self.conversationCounts?.append(count)
            }
        }
        
        return true
    }
}
