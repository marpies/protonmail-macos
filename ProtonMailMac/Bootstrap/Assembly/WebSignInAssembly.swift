//
//  WebSignInAssembly.swift
//  ProtonMailMac
//
//  Created by Marcel Piešťanský on 04.11.2021.
//  Copyright (c) 2021 marpies. All rights reserved.
//

import Foundation
import Swinject

struct WebSignInAssembly: Assembly {
    
    func assemble(container: Container) {
        container.register(WebSignInWorker.self) { r in
            return WebSignInWorker(resolver: r)
        }
        container.register(WebSignInPresenter.self) { r in
            return WebSignInPresenter()
        }.initCompleted { r, presenter in
            presenter.viewController = r.resolve(WebSignInViewController.self)
        }
        container.register(WebSignInInteractor.self) { r in
            let obj = WebSignInInteractor()
            obj.worker = r.resolve(WebSignInWorker.self)
            obj.presenter = r.resolve(WebSignInPresenter.self)
            return obj
        }
        container.register(WebSignInViewController.self) { r in
            return WebSignInViewController()
        }.initCompleted { r, vc in
            vc.interactor = r.resolve(WebSignInBusinessLogic.self)
            vc.router = r.resolve(WebSignInRouter.self)
        }
        container.register(WebSignInDataStore.self) { r in
            return r.resolve(WebSignInInteractor.self)!
        }
        container.register(WebSignInBusinessLogic.self) { r in
            return r.resolve(WebSignInInteractor.self)!
        }
        container.register(WebSignInRouter.self) { r in
            return WebSignInRouter()
        }.initCompleted { r, router in
            router.viewController = r.resolve(WebSignInViewController.self)
            router.dataStore = r.resolve(WebSignInDataStore.self)
        }
    }
    
}
