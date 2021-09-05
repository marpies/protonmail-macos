//
//  MessagesInteractor.swift
//  ProtonMailMac
//
//  Created by Marcel Piešťanský on 05.09.2021.
//  Copyright (c) 2021 marpies. All rights reserved.
//

import Foundation

protocol MessagesBusinessLogic {
	func loadData(request: Messages.Init.Request)
}

protocol MessagesDataStore {
	
}

class MessagesInteractor: MessagesBusinessLogic, MessagesDataStore, MessagesWorkerDelegate {

	var worker: MessagesWorker?

	var presenter: MessagesPresentationLogic?
	
	//
	// MARK: - Load data
	//
	
	func loadData(request: Messages.Init.Request) {
		self.worker?.delegate = self
		self.worker?.loadData(request: request)
	}
    
    //
    // MARK: - Worker delegate
    //
    
    func MessagesDidLoad(response: Messages.Init.Response) {
        self.presenter?.presentData(response: response)
    }
    
}
