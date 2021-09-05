//
//  MessageDetailsAssembly.swift
//  ProtonMailMac
//
//  Created by Marcel Piešťanský on 05.09.2021.
//  Copyright (c) 2021 marpies. All rights reserved.
//

import Foundation
import Swinject

struct MessageDetailsAssembly: Assembly {
    
    func assemble(container: Container) {
        container.register(MessageDetailsWorker.self) { r in
            return MessageDetailsWorker(resolver: r)
        }
        container.register(MessageDetailsPresenter.self) { r in
            return MessageDetailsPresenter()
        }.initCompleted { r, presenter in
            presenter.viewController = r.resolve(MessageDetailsViewController.self)
        }
        container.register(MessageDetailsInteractor.self) { r in
            let obj = MessageDetailsInteractor()
            obj.worker = r.resolve(MessageDetailsWorker.self)
            obj.presenter = r.resolve(MessageDetailsPresenter.self)
            return obj
        }
        container.register(MessageDetailsViewController.self) { r in
            let vc = MessageDetailsViewController()
            vc.interactor = r.resolve(MessageDetailsBusinessLogic.self)
            vc.router = r.resolve(MessageDetailsRouter.self)
            return vc
        }
        container.register(MessageDetailsDataStore.self) { r in
            return r.resolve(MessageDetailsInteractor.self)!
        }
        container.register(MessageDetailsBusinessLogic.self) { r in
            return r.resolve(MessageDetailsInteractor.self)!
        }
        container.register(MessageDetailsRouter.self) { r in
            return MessageDetailsRouter()
        }.initCompleted { r, router in
            router.viewController = r.resolve(MessageDetailsViewController.self)
            router.dataStore = r.resolve(MessageDetailsDataStore.self)
        }
    }
    
}
