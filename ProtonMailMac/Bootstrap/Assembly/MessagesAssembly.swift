//
//  MessagesAssembly.swift
//  ProtonMailMac
//
//  Created by Marcel Piešťanský on 05.09.2021.
//  Copyright (c) 2021 marpies. All rights reserved.
//

import Foundation
import Swinject

struct MessagesAssembly: Assembly {
    
    func assemble(container: Container) {
        container.register(MessagesWorker.self) { r in
            return MessagesWorker(resolver: r)
        }
        container.register(MessagesPresenter.self) { r in
            return MessagesPresenter()
        }.initCompleted { r, presenter in
            presenter.viewController = r.resolve(MessagesViewController.self)
        }
        container.register(MessagesInteractor.self) { r in
            let obj = MessagesInteractor()
            obj.worker = r.resolve(MessagesWorker.self)
            obj.presenter = r.resolve(MessagesPresenter.self)
            return obj
        }
        container.register(MessagesViewController.self) { r in
            let vc = MessagesViewController()
            vc.interactor = r.resolve(MessagesBusinessLogic.self)
            vc.router = r.resolve(MessagesRouter.self)
            return vc
        }
        container.register(MessagesDataStore.self) { r in
            return r.resolve(MessagesInteractor.self)!
        }
        container.register(MessagesBusinessLogic.self) { r in
            return r.resolve(MessagesInteractor.self)!
        }
        container.register(MessagesRouter.self) { r in
            return MessagesRouter()
        }.initCompleted { r, router in
            router.viewController = r.resolve(MessagesViewController.self)
            router.dataStore = r.resolve(MessagesDataStore.self)
        }
    }
    
}
