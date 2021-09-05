//
//  MessageDetailsInteractor.swift
//  ProtonMailMac
//
//  Created by Marcel Piešťanský on 05.09.2021.
//  Copyright (c) 2021 marpies. All rights reserved.
//

import Foundation

protocol MessageDetailsBusinessLogic {
	func loadData(request: MessageDetails.Init.Request)
}

protocol MessageDetailsDataStore {
	
}

class MessageDetailsInteractor: MessageDetailsBusinessLogic, MessageDetailsDataStore, MessageDetailsWorkerDelegate {

	var worker: MessageDetailsWorker?

	var presenter: MessageDetailsPresentationLogic?
	
	//
	// MARK: - Load data
	//
	
	func loadData(request: MessageDetails.Init.Request) {
		self.worker?.delegate = self
		self.worker?.loadData(request: request)
	}
    
    //
    // MARK: - Worker delegate
    //
    
    func MessageDetailsDidLoad(response: MessageDetails.Init.Response) {
        self.presenter?.presentData(response: response)
    }
    
}
