//
//  MainAssembly.swift
//  ProtonMailMac
//
//  Created by Marcel Piešťanský on 27.08.2021.
//  Copyright © 2021 marpies. All rights reserved.
//

import Foundation
import Swinject

struct MainAssembly: Assembly {
    
    func assemble(container: Container) {
        container.register(MainWorker.self) { r in
            return MainWorker(resolver: r)
        }
        container.register(MainPresenter.self) { r in
            return MainPresenter()
        }.initCompleted { r, presenter in
            presenter.viewController = r.resolve(MainViewController.self)
        }
        container.register(MainInteractor.self) { r in
            let obj = MainInteractor()
            obj.worker = r.resolve(MainWorker.self)
            obj.presenter = r.resolve(MainPresenter.self)
            return obj
        }
        container.register(MainViewController.self) { r in
            let vc = MainViewController()
            vc.interactor = r.resolve(MainBusinessLogic.self)
            vc.router = r.resolve(MainRouter.self)
            vc.sidebarViewController = r.resolve(MailboxSidebarViewController.self)
            vc.conversationsViewController = r.resolve(ConversationsViewController.self)
            vc.conversationDetailsViewController = r.resolve(ConversationDetailsViewController.self)
            return vc
        }
        container.register(MainDataStore.self) { r in
            return r.resolve(MainInteractor.self)!
        }
        container.register(MainBusinessLogic.self) { r in
            return r.resolve(MainInteractor.self)!
        }
        container.register(MainRouter.self) { r in
            return MainRouter()
        }.initCompleted { r, router in
            router.viewController = r.resolve(MainViewController.self)
            router.dataStore = r.resolve(MainDataStore.self)
        }
    }
    
}
