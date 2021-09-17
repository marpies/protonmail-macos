//
//  DatabaseAssembly.swift
//  ProtonMailMac
//
//  Created by Marcel Piešťanský on 06.09.2021.
//  Copyright (c) 2021 marpies. All rights reserved.
//

import Foundation
import Swinject

struct DatabaseAssembly: Assembly {
    
    func assemble(container: Container) {
        container.register(CoreDataService.self) { _ in
            return CoreDataService(container: CoreDataStore().defaultContainer)
        }.inObjectScope(.container)
        container.register(LabelsDatabaseManaging.self) { r in
            return r.resolve(CoreDataService.self)!
        }
        container.register(MessagesDatabaseManaging.self) { r in
            return r.resolve(CoreDataService.self)!
        }
        container.register(UserEventsDatabaseManaging.self) { r in
            return r.resolve(CoreDataService.self)!
        }
        container.register(UserEventsDatabaseProcessing.self) { r in
            return r.resolve(CoreDataService.self)!
        }
        container.register(LabelUpdateDatabaseManaging.self) { r in
            return r.resolve(CoreDataService.self)!
        }
        container.register(ConversationsDatabaseManaging.self) { r in
            return r.resolve(CoreDataService.self)!
        }
    }
    
}
