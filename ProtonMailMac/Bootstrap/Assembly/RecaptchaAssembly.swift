//
//  RecaptchaAssembly.swift
//  ProtonMailMac
//
//  Created by Marcel Piešťanský on 01.11.2021.
//  Copyright (c) 2021 marpies. All rights reserved.
//

import Foundation
import Swinject

struct RecaptchaAssembly: Assembly {
    
    func assemble(container: Container) {
        container.register(RecaptchaWorker.self) { r in
            return RecaptchaWorker(resolver: r)
        }
        container.register(RecaptchaPresenter.self) { r in
            return RecaptchaPresenter()
        }.initCompleted { r, presenter in
            presenter.viewController = r.resolve(RecaptchaViewController.self)
        }
        container.register(RecaptchaInteractor.self) { r in
            let obj = RecaptchaInteractor()
            obj.worker = r.resolve(RecaptchaWorker.self)
            obj.presenter = r.resolve(RecaptchaPresenter.self)
            return obj
        }
        container.register(RecaptchaViewController.self) { r in
            return RecaptchaViewController()
        }.initCompleted { r, vc in
            vc.interactor = r.resolve(RecaptchaBusinessLogic.self)
            vc.router = r.resolve(RecaptchaRouter.self)
        }
        container.register(RecaptchaDataStore.self) { r in
            return r.resolve(RecaptchaInteractor.self)!
        }
        container.register(RecaptchaBusinessLogic.self) { r in
            return r.resolve(RecaptchaInteractor.self)!
        }
        container.register(RecaptchaRouter.self) { r in
            return RecaptchaRouter()
        }.initCompleted { r, router in
            router.viewController = r.resolve(RecaptchaViewController.self)
            router.dataStore = r.resolve(RecaptchaDataStore.self)
        }
    }
    
}
