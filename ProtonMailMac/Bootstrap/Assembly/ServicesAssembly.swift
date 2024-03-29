//
//  ServicesAssembly.swift
//  ProtonMailMac
//
//  Created by Marcel Piešťanský on 08.09.2021.
//  Copyright (c) 2021 marpies. All rights reserved.
//

import Foundation
import Swinject

struct ServicesAssembly: Assembly {
    
    func assemble(container: Container) {
        container.register(UserEventsProcessing.self) { r in
            return UserEventsService(resolver: r)
        }.inObjectScope(.container)
        
        container.register(MailboxManaging.self) { (r: Resolver, userId: String) in
            return MailboxManagingWorker(userId: userId, resolver: r)
        }.inObjectScope(.transient)
        
        container.register(MessagesLoading.self) { (r: Resolver, labelId: String, userId: String, apiService: ApiService) in
            return MessagesLoadingWorker(resolver: r, labelId: labelId, userId: userId, apiService: apiService)
        }.inObjectScope(.transient)
        
        container.register(MessageOpsProcessing.self) { (r: Resolver, userId: String, apiService: ApiService) in
            return MessageOpsService(userId: userId, apiService: apiService, resolver: r)
        }.inObjectScope(.transient)
        
        container.register(MessageQueue.self) { (r: Resolver, queueName: String) in
            return MessageQueue(queueName: queueName)
        }.inObjectScope(.container)
        
        container.register(ConversationsLoading.self) { (r: Resolver, labelId: String, userId: String, apiService: ApiService) in
            return ConversationsLoadingWorker(resolver: r, labelId: labelId, userId: userId, apiService: apiService)
        }.inObjectScope(.transient)
        
        container.register(ConversationOpsProcessing.self) { (r: Resolver, userId: String, apiService: ApiService) in
            return ConversationOpsService(userId: userId, apiService: apiService, resolver: r)
        }.inObjectScope(.transient)
        
        container.register(MessageBodyLoading.self) { (r: Resolver, apiService: ApiService) in
            return MessageBodyLoadingWorker(apiService: apiService, messagesDb: r.resolve(MessagesDatabaseManaging.self)!)
        }.inObjectScope(.transient)
        
        container.register(MessageBodyDecrypting.self) { r in
            return MessageBodyDecryptingWorker()
        }.inObjectScope(.transient)
        
        container.register(MessageInlineAttachmentDecrypting.self) { (r: Resolver, apiService: ApiService) in
            return MessageInlineAttachmentDecryptingWorker(resolver: r, apiService: apiService)
        }.inObjectScope(.transient)
    }
    
}
