//
//  MailboxSidebarAssembly.swift
//  ProtonMailMac
//
//  Created by Marcel Piešťanský on 27.08.2021.
//  Copyright (c) 2021 marpies. All rights reserved.
//

import Foundation
import Swinject

struct MailboxSidebarAssembly: Assembly {
    
    func assemble(container: Container) {
        container.register(MailboxSidebarWorker.self) { r in
            return MailboxSidebarWorker(resolver: r)
        }
        container.register(MailboxSidebarPresenter.self) { r in
            return MailboxSidebarPresenter()
        }.initCompleted { r, presenter in
            presenter.viewController = r.resolve(MailboxSidebarViewController.self)
        }
        container.register(MailboxSidebarInteractor.self) { r in
            let obj = MailboxSidebarInteractor()
            obj.worker = r.resolve(MailboxSidebarWorker.self)
            obj.presenter = r.resolve(MailboxSidebarPresenter.self)
            return obj
        }
        container.register(MailboxSidebarViewController.self) { r in
            let vc = MailboxSidebarViewController()
            vc.interactor = r.resolve(MailboxSidebarBusinessLogic.self)
            vc.router = r.resolve(MailboxSidebarRouter.self)
            return vc
        }
        container.register(MailboxSidebarDataStore.self) { r in
            return r.resolve(MailboxSidebarInteractor.self)!
        }
        container.register(MailboxSidebarBusinessLogic.self) { r in
            return r.resolve(MailboxSidebarInteractor.self)!
        }
        container.register(MailboxSidebarRouter.self) { r in
            return MailboxSidebarRouter()
        }.initCompleted { r, router in
            router.viewController = r.resolve(MailboxSidebarViewController.self)
            router.dataStore = r.resolve(MailboxSidebarDataStore.self)
        }
    }
    
}
