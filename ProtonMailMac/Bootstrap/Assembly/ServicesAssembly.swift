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
        
        container.register(MessagesLoading.self) { (r: Resolver, labelId: String, userId: String) in
            return MessagesLoadingWorker(resolver: r, labelId: labelId, userId: userId)
        }.inObjectScope(.transient)
        
        container.register(MessageOpsProcessing.self) { (r: Resolver, userId: String) in
            return MessageOpsService(userId: userId, resolver: r)
        }.inObjectScope(.transient)
        
        container.register(MessageQueue.self) { (r: Resolver, queueName: String) in
            return MessageQueue(queueName: queueName)
        }.inObjectScope(.container)
        
        container.register(ConversationsLoading.self) { (r: Resolver, labelId: String, userId: String) in
            return ConversationsLoadingWorker(resolver: r, labelId: labelId, userId: userId)
        }.inObjectScope(.transient)
        
        container.register(ConversationOpsProcessing.self) { (r: Resolver, userId: String) in
            return ConversationOpsService(userId: userId, resolver: r)
        }.inObjectScope(.transient)
    }
    
}
