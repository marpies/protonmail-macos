//
//  SignInAssembly.swift
//  ProtonMailMac
//
//  Created by Marcel Piešťanský on 26.08.2021.
//  Copyright © 2021 marpies. All rights reserved.
//

import Foundation
import Swinject

struct SignInAssembly: Assembly {
    
    func assemble(container: Container) {
        container.register(SignInProcessing.self) { r, username, password in
            return SignInProcessingWorker(username: username, password: password)
        }
        container.register(SignInWorker.self) { r in
            return SignInWorker(resolver: r)
        }
        container.register(SignInInteractor.self) { r in
            let obj = SignInInteractor()
            obj.worker = r.resolve(SignInWorker.self)
            return obj
        }
        container.register(SignInViewController.self) { r in
            return SignInViewController(resolver: r)
        }
    }
    
}
