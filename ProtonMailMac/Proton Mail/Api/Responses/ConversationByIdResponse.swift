//
//  ConversationByIdResponse.swift
//  ProtonMailMac
//
//  Created by Marcel Piešťanský on 17.09.2021.
//  Copyright © 2021 marpies. All rights reserved.
//

import Foundation

final class ConversationByIdResponse: Response {
    var messages: [[String: Any]]?
    var conversation: [String: Any]?
    
    override func parseResponse(_ response: [String : Any]) -> Bool {
        self.code = response["Code"] as? Int ?? 0
        self.conversation = response["Conversation"] as? [String: Any]
        self.messages = response["Messages"] as? [[String: Any]]
        
        self.updateLabelIds()
        return true
    }
    
    private func updateLabelIds() {
        guard var labelIds = self.conversation?["LabelIDs"] as? [String], labelIds.isEmpty,
              let labels = self.conversation?["Labels"] as? [[String: Any]] else { return }
        
        for json in labels {
            guard let id = json["ID"] as? String else { continue }
            
            labelIds.append(id)
        }
        
        self.conversation?["LabelIDs"] = labelIds
    }
    
}
