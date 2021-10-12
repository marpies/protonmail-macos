//
//  MainInteractor.swift
//  ProtonMailMac
//
//  Created by Marcel Piešťanský on 25.08.2021.
//  Copyright (c) 2021 marpies. All rights reserved.
//

import Foundation

protocol MainBusinessLogic {
	func loadData(request: Main.Init.Request)
    func loadTitle(request: Main.LoadTitle.Request)
}

protocol MainDataStore {
	
}

class MainInteractor: MainBusinessLogic, MainDataStore, MainWorkerDelegate {

    var worker: MainWorker?

	var presenter: MainPresentationLogic?
	
	//
	// MARK: - Load data
	//
	
	func loadData(request: Main.Init.Request) {
		self.worker?.delegate = self
		self.worker?.loadData(request: request)
	}
    
    //
    // MARK: - Load title
    //
    
    func loadTitle(request: Main.LoadTitle.Request) {
        self.worker?.loadTitle(request: request)
    }
    
    //
    // MARK: - Worker delegate
    //
    
    func mailboxDidLoad(response: Main.Init.Response) {
        self.presenter?.presentData(response: response)
    }
    
    func mailboxTitleDidLoad(response: Main.LoadTitle.Response) {
        self.presenter?.presentTitle(response: response)
    }
    
}
