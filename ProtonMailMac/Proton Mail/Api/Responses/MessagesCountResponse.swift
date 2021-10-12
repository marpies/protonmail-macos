//
//  MessagesCountResponse.swift
//  ProtonMailMac
//
//  Created by Marcel Piešťanský on 11.10.2021.
//  Copyright © 2021 marpies. All rights reserved.
//

import Foundation

final class MessagesCountResponse: Response {
    
    private(set) var messageCounts: [LabelMessageCount]?
    
    override func parseResponse(_ response: [String : Any]) -> Bool {
        if let counts = response["Counts"] as? [[String: Any]] {
            self.messageCounts = []
            
            // Count only outbox/draft labels for messages, other folders are using conversation mode
            let targetIds: Set<String> = ["1", "2", "7", "8"]
            
            for json in counts {
                guard let labelId = json.getString("LabelID"),
                      targetIds.contains(labelId),
                      let total = json.getInt("Total"),
                      let unread = json.getInt("Unread") else { continue }
                
                let count: LabelMessageCount = LabelMessageCount(labelId: labelId, total: total, unread: unread)
                self.messageCounts?.append(count)
            }
        }
        
        return true
    }
}
