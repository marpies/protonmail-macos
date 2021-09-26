//
//  MessageBodyRemoteContentChecking.swift
//  ProtonMailMac
//
//  Created by Marcel Piešťanský on 26.09.2021.
//  Copyright © 2021 marpies. All rights reserved.
//

import Foundation

protocol MessageBodyRemoteContentChecking {
    func checkHasMessageRemoteContent(body: String, contentPolicy: WebContents.RemoteContentPolicy, completion: @escaping (Bool) -> Void)
}

extension MessageBodyRemoteContentChecking {
    
    func checkHasMessageRemoteContent(body: String, contentPolicy: WebContents.RemoteContentPolicy, completion: @escaping (Bool) -> Void) {
        guard contentPolicy != .allowed else {
            completion(false)
            return
        }
        
        DispatchQueue.global(qos: .userInitiated).async {
            let hasRemoteContent: Bool = body.hasRemoteContent()
            
            DispatchQueue.main.async {
                completion(hasRemoteContent)
            }
        }
    }
    
}
