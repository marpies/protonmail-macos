//
//  SetupAssembly.swift
//  ProtonMailMac
//
//  Created by Marcel Piešťanský on 26.08.2021.
//  Copyright © 2021 marpies. All rights reserved.
//

import Foundation
import Swinject

struct SetupAssembly: Assembly {
    
    func assemble(container: Container) {
        container.register(SetupWorker.self) { r in
            return SetupWorker(usersManager: r.resolve(UsersManager.self)!, keymaker: r.resolve(KeymakerWrapper.self)!)
        }
        container.register(SetupInteractor.self) { r in
            let obj = SetupInteractor()
            obj.worker = r.resolve(SetupWorker.self)
            return obj
        }
        container.register(SetupViewController.self) { r in
            return SetupViewController(resolver: r)
        }
    }
    
}
