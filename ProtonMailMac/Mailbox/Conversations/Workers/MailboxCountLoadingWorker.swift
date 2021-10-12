//
//  MailboxCountLoadingWorker.swift
//  ProtonMailMac
//
//  Created by Marcel Piešťanský on 11.10.2021.
//  Copyright © 2021 marpies. All rights reserved.
//

import Foundation

struct MailboxCountLoadingWorker {
    
    let apiService: ApiService

    init(apiService: ApiService) {
        self.apiService = apiService
    }
    
    func load(completion: @escaping ([LabelMessageCount]?) -> Void) {
        let conversationRequest: ConversationsCountRequest = ConversationsCountRequest()
        
        self.apiService.request(conversationRequest, completion: { (response: ConversationsCountResponse) in
            guard let conversationCounts = response.conversationCounts else {
                completion(nil)
                return
            }
            
            let messageRequest: MessagesCountRequest = MessagesCountRequest()
            self.apiService.request(messageRequest, completion: { (response: MessagesCountResponse) in
                guard let messageCounts = response.messageCounts else {
                    completion(nil)
                    return
                }
                
                completion(messageCounts + conversationCounts)
            })
        })
    }
    
}
