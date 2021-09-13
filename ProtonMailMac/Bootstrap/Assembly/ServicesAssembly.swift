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
    }
    
}
