//
//  SetupWorker.swift
//  ProtonMailMac
//
//  Created by Marcel Piešťanský on 24.08.2021.
//  Copyright (c) 2021 marpies. All rights reserved.
//

import Foundation
import Swinject

protocol SetupWorkerDelegate: AnyObject {
    func appDidInitialize(response: Setup.Init.Response)
}

class SetupWorker {
    
    let usersManager: UsersManager
    let keymaker: KeymakerWrapper

	weak var delegate: SetupWorkerDelegate?
    
    init(usersManager: UsersManager, keymaker: KeymakerWrapper) {
        self.usersManager = usersManager
        self.keymaker = keymaker
    }

	func initApp(request: Setup.Init.Request) {
        // Restore existing accounts if we have the main key
        if self.keymaker.mainKeyExists() {
            self.usersManager.restore()
        }
        
        let initialSection: App.Section
        
        if self.usersManager.isLoggedIn {
            initialSection = .mailbox
        } else {
            initialSection = .signIn
        }
        
        let response: Setup.Init.Response = Setup.Init.Response(initialSection: initialSection)
        self.delegate?.appDidInitialize(response: response)
	}

}
