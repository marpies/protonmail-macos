//
//  ConversationDetailsAssembly.swift
//  ProtonMailMac
//
//  Created by Marcel Piešťanský on 17.09.2021.
//  Copyright (c) 2021 marpies. All rights reserved.
//

import Foundation
import Swinject

struct ConversationDetailsAssembly: Assembly {
    
    func assemble(container: Container) {
        container.register(ConversationDetailsWorker.self) { r in
            return ConversationDetailsWorker(resolver: r)
        }
        container.register(ConversationDetailsPresenter.self) { r in
            return ConversationDetailsPresenter()
        }.initCompleted { r, presenter in
            presenter.viewController = r.resolve(ConversationDetailsViewController.self)
        }
        container.register(ConversationDetailsInteractor.self) { r in
            let obj = ConversationDetailsInteractor()
            obj.worker = r.resolve(ConversationDetailsWorker.self)
            obj.presenter = r.resolve(ConversationDetailsPresenter.self)
            return obj
        }
        container.register(ConversationDetailsViewController.self) { r in
            let vc = ConversationDetailsViewController()
            vc.interactor = r.resolve(ConversationDetailsBusinessLogic.self)
            vc.router = r.resolve(ConversationDetailsRouter.self)
            return vc
        }
        container.register(ConversationDetailsDataStore.self) { r in
            return r.resolve(ConversationDetailsInteractor.self)!
        }
        container.register(ConversationDetailsBusinessLogic.self) { r in
            return r.resolve(ConversationDetailsInteractor.self)!
        }
        container.register(ConversationDetailsRouter.self) { r in
            return ConversationDetailsRouter()
        }.initCompleted { r, router in
            router.viewController = r.resolve(ConversationDetailsViewController.self)
            router.dataStore = r.resolve(ConversationDetailsDataStore.self)
        }
    }
    
}
