//
//  ManagersAssembly.swift
//  ProtonMailMac
//
//  Created by Marcel Piešťanský on 26.08.2021.
//  Copyright © 2021 marpies. All rights reserved.
//

import Foundation
import Swinject
import PMKeymaker

struct ManagersAssembly: Assembly {
    
    func assemble(container: Container) {
        container.register(KeyValueStore.self) { _ in
            return DefaultKeyValueStore()
        }.inObjectScope(.container)
        
        container.register(SettingsProvider.self) { _ in
            return DefaultKeyValueStore()
        }.inObjectScope(.container)
        
        container.register(KeymakerWrapper.self) { r in
            return KeymakerWrapper(keyValueStore: r.resolve(KeyValueStore.self)!, settingsProvider: r.resolve(SettingsProvider.self)!)
        }.inObjectScope(.container)
        
        container.register(UsersManager.self) { r in
            return UsersManager(keymaker: r.resolve(KeymakerWrapper.self)!, keyValueStore: r.resolve(KeyValueStore.self)!)
        }.inObjectScope(.container)
        
        container.register(KeychainWrapper.self) { _ in
            return KeychainWrapper()
        }.inObjectScope(.container)
    }
    
}
