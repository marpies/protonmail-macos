//
//  MailboxAssembly.swift
//  ProtonMailMac
//
//  Created by Marcel Piešťanský on 16.09.2021.
//  Copyright (c) 2021 marpies. All rights reserved.
//

import Foundation
import Swinject

struct MailboxAssembly: Assembly {
    
    func assemble(container: Container) {
        container.register(MailboxWorker.self) { r in
            return MailboxWorker(resolver: r)
        }
        container.register(MailboxPresenter.self) { r in
            return MailboxPresenter()
        }.initCompleted { r, presenter in
            presenter.viewController = r.resolve(MailboxViewController.self)
        }
        container.register(MailboxInteractor.self) { r in
            let obj = MailboxInteractor()
            obj.worker = r.resolve(MailboxWorker.self)
            obj.presenter = r.resolve(MailboxPresenter.self)
            return obj
        }
        container.register(MailboxViewController.self) { r in
            return MailboxViewController()
        }.initCompleted { r, vc in
            vc.interactor = r.resolve(MailboxBusinessLogic.self)
            vc.router = r.resolve(MailboxRouter.self)
        }
        container.register(MailboxDataStore.self) { r in
            return r.resolve(MailboxInteractor.self)!
        }
        container.register(MailboxBusinessLogic.self) { r in
            return r.resolve(MailboxInteractor.self)!
        }
        container.register(MailboxRouter.self) { r in
            return MailboxRouter()
        }.initCompleted { r, router in
            router.viewController = r.resolve(MailboxViewController.self)
            router.dataStore = r.resolve(MailboxDataStore.self)
        }
    }
    
}
