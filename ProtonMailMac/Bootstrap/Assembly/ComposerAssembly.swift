//
//  ComposerAssembly.swift
//  ProtonMailMac
//
//  Created by Marcel Piešťanský on 26.11.2021.
//  Copyright (c) 2021 marpies. All rights reserved.
//

import Foundation
import Swinject

struct ComposerAssembly: Assembly {
    
    func assemble(container: Container) {
        container.register(ComposerWorker.self) { r in
            return ComposerWorker(resolver: r)
        }
        container.register(ComposerPresenter.self) { r in
            return ComposerPresenter()
        }.initCompleted { r, presenter in
            presenter.viewController = r.resolve(ComposerViewController.self)
        }
        container.register(ComposerInteractor.self) { r in
            let obj = ComposerInteractor()
            obj.worker = r.resolve(ComposerWorker.self)
            obj.presenter = r.resolve(ComposerPresenter.self)
            return obj
        }
        container.register(ComposerViewController.self) { r in
            return ComposerViewController()
        }.initCompleted { r, vc in
            vc.interactor = r.resolve(ComposerBusinessLogic.self)
            vc.router = r.resolve(ComposerRouter.self)
        }
        container.register(ComposerDataStore.self) { r in
            return r.resolve(ComposerInteractor.self)!
        }
        container.register(ComposerBusinessLogic.self) { r in
            return r.resolve(ComposerInteractor.self)!
        }
        container.register(ComposerRouter.self) { r in
            return ComposerRouter()
        }.initCompleted { r, router in
            router.viewController = r.resolve(ComposerViewController.self)
            router.dataStore = r.resolve(ComposerDataStore.self)
        }
    }
    
}
