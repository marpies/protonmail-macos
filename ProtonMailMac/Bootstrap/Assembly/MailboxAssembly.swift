//
//  MailboxAssembly.swift
//  ProtonMailMac
//
//  Created by Marcel Piešťanský on 27.08.2021.
//  Copyright © 2021 marpies. All rights reserved.
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
            let vc = MailboxViewController()
            vc.interactor = r.resolve(MailboxBusinessLogic.self)
            vc.router = r.resolve(MailboxRouter.self)
            vc.sidebarViewController = r.resolve(MailboxSidebarViewController.self)
            vc.conversationsViewController = r.resolve(ConversationsViewController.self)
            vc.conversationDetailsViewController = r.resolve(ConversationDetailsViewController.self)
            return vc
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
