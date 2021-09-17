//
//  ConversationDetailsInteractor.swift
//  ProtonMailMac
//
//  Created by Marcel Piešťanský on 17.09.2021.
//  Copyright (c) 2021 marpies. All rights reserved.
//

import Foundation

protocol ConversationDetailsBusinessLogic {
	func loadData(request: ConversationDetails.Init.Request)
}

protocol ConversationDetailsDataStore {
	
}

class ConversationDetailsInteractor: ConversationDetailsBusinessLogic, ConversationDetailsDataStore, ConversationDetailsWorkerDelegate {

	var worker: ConversationDetailsWorker?

	var presenter: ConversationDetailsPresentationLogic?
	
	//
	// MARK: - Load data
	//
	
	func loadData(request: ConversationDetails.Init.Request) {
		self.worker?.delegate = self
		self.worker?.loadData(request: request)
	}
    
    //
    // MARK: - Worker delegate
    //
    
    func ConversationDetailsDidLoad(response: ConversationDetails.Init.Response) {
        self.presenter?.presentData(response: response)
    }
    
}
