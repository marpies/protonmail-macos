//
//  TwoFactorInputInteractor.swift
//  ProtonMailMac
//
//  Created by Marcel Piešťanský on 26.08.2021.
//  Copyright (c) 2021 marpies. All rights reserved.
//

import Foundation

protocol TwoFactorInputBusinessLogic {
	func loadInitialData(request: TwoFactorInput.Init.Request)
    func processInput(request: TwoFactorInput.ProcessInput.Request)
}

protocol TwoFactorInputDataStore {
	
}

class TwoFactorInputInteractor: TwoFactorInputBusinessLogic, TwoFactorInputDataStore {

	var presenter: TwoFactorInputPresentationLogic?
	
	//
	// MARK: - Load initial data
	//
	
	func loadInitialData(request: TwoFactorInput.Init.Request) {
        self.presenter?.presentInitialData(response: TwoFactorInput.Init.Response())
	}
    
    //
    // MARK: - Process input
    //
    
    func processInput(request: TwoFactorInput.ProcessInput.Request) {
        if request.input.isEmpty {
            self.presenter?.presentInvalidField()
        } else {
            self.presenter?.presentSceneDismiss()
        }
    }
    
}
