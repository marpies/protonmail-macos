//
//  MessageBodyLoadingWorker.swift
//  ProtonMailMac
//
//  Created by Marcel Piešťanský on 22.09.2021.
//  Copyright © 2021 marpies. All rights reserved.
//

import Foundation

protocol MessageBodyLoading {
    func load(messageId: String, completion: @escaping (String?) -> Void)
}

struct MessageBodyLoadingWorker: MessageBodyLoading {
    
    let apiService: ApiService
    let messagesDb: MessagesDatabaseManaging

    init(apiService: ApiService, messagesDb: MessagesDatabaseManaging) {
        self.apiService = apiService
        self.messagesDb = messagesDb
    }
    
    func load(messageId: String, completion: @escaping (String?) -> Void) {
        // Get cached body
        if let message = self.messagesDb.loadMessage(id: messageId), !message.body.isEmpty {
            completion(message.body)
            return
        }
        
        // Fetch body from the server
        let request: MessageDetailRequest = MessageDetailRequest(messageId: messageId)
        self.apiService.request(request) { (response: MessageDetailResponse) in
            if let id = response.messageId, let body = response.body {
                self.messagesDb.saveBody(messageId: id, body: body) { _ in
                    // Even if not success saving, provide the body, we will just try saving it again next time
                    completion(body)
                }
            } else {
                PMLog.D("Error loading message body: \(response.error ?? .unknownError())")
                completion(nil)
            }
        }
    }
    
}
