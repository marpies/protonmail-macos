//
//  ComposerInteractor.swift
//  ProtonMailMac
//
//  Created by Marcel Piešťanský on 26.11.2021.
//  Copyright (c) 2021 marpies. All rights reserved.
//

import Foundation

protocol ComposerBusinessLogic {
	func loadData(request: Composer.Init.Request)
}

protocol ComposerDataStore {
	
}

class ComposerInteractor: ComposerBusinessLogic, ComposerDataStore, ComposerWorkerDelegate {

	var worker: ComposerWorker?

	var presenter: ComposerPresentationLogic?
	
	//
	// MARK: - Load data
	//
	
	func loadData(request: Composer.Init.Request) {
		self.worker?.delegate = self
		self.worker?.loadInitialData(request: request)
	}
    
    //
    // MARK: - Worker delegate
    //
    
    func composerDidLoad(response: Composer.Init.Response) {
        self.presenter?.presentInitialData(response: response)
    }
    
    func composerToolbarDidUpdate(response: Composer.UpdateToolbar.Response) {
        self.presenter?.presentToolbarUpdate(response: response)
    }
    
}
