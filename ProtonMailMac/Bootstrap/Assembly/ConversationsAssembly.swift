//
//  ConversationsAssembly.swift
//  ProtonMailMac
//
//  Created by Marcel Piešťanský on 16.09.2021.
//  Copyright (c) 2021 marpies. All rights reserved.
//

import Foundation
import Swinject

struct ConversationsAssembly: Assembly {
    
    func assemble(container: Container) {
        container.register(ConversationsWorker.self) { r in
            return ConversationsWorker(resolver: r)
        }
        container.register(ConversationsPresenter.self) { r in
            return ConversationsPresenter()
        }.initCompleted { r, presenter in
            presenter.viewController = r.resolve(ConversationsViewController.self)
        }
        container.register(ConversationsInteractor.self) { r in
            let obj = ConversationsInteractor()
            obj.worker = r.resolve(ConversationsWorker.self)
            obj.presenter = r.resolve(ConversationsPresenter.self)
            return obj
        }
        container.register(ConversationsViewController.self) { r in
            let vc = ConversationsViewController()
            vc.interactor = r.resolve(ConversationsBusinessLogic.self)
            vc.router = r.resolve(ConversationsRouter.self)
            return vc
        }
        container.register(ConversationsDataStore.self) { r in
            return r.resolve(ConversationsInteractor.self)!
        }
        container.register(ConversationsBusinessLogic.self) { r in
            return r.resolve(ConversationsInteractor.self)!
        }
        container.register(ConversationsRouter.self) { r in
            return ConversationsRouter()
        }.initCompleted { r, router in
            router.viewController = r.resolve(ConversationsViewController.self)
            router.dataStore = r.resolve(ConversationsDataStore.self)
        }
    }
    
}
