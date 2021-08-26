//
//  SetupInteractor.swift
//  ProtonMailMac
//
//  Created by Marcel Piešťanský on 24.08.2021.
//  Copyright (c) 2021 marpies. All rights reserved.
//

import Foundation

protocol SetupBusinessLogic {
	func initApp(request: Setup.Init.Request)
}

protocol SetupDataStore {
	
}

class SetupInteractor: SetupBusinessLogic, SetupDataStore, SetupWorkerDelegate {

    var worker: SetupWorker?

	var presenter: SetupPresentationLogic?
	
	//
	// MARK: - Init app
	//
	
	func initApp(request: Setup.Init.Request) {
        self.presenter?.presentLaunchContent()
        
		self.worker?.delegate = self
		
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.worker?.initApp(request: request)
        }
	}
    
    //
    // MARK: - Worker delegate
    //
    
    func appDidInitialize(response: Setup.Init.Response) {
        switch response.initialSection {
        case .setup:
            // Cannot happen
            fatalError("Unexpected application state.")
        case .signIn:
            self.presenter?.presentSignIn()
        case .mailbox:
            self.presenter?.presentMailbox()
        }
    }
}
