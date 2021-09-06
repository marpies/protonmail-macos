//
//  BootstrapAssembly.swift
//  ProtonMailMac
//
//  Created by Marcel Piešťanský on 26.08.2021.
//  Copyright © 2021 marpies. All rights reserved.
//

import Foundation
import Swinject

struct BootstrapAssembly: Assembly {
    
    func assemble(container: Container) {
        container.register(AppViewController.self) { r in
            return AppViewController(resolver: r)
        }
        container.register(ApiService.self) { r in
            return PMApiService()
        }.inObjectScope(.transient)
        container.register(CoreDataService.self) { _ in
            return CoreDataService(container: CoreDataStore().defaultContainer)
        }.inObjectScope(.container)
        container.register(LabelsDatabaseManaging.self) { r in
            return r.resolve(CoreDataService.self)!
        }
    }
    
}
