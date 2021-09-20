//
//  ConversationDetailsInteractor.swift
//  ProtonMailMac
//
//  Created by Marcel Piešťanský on 17.09.2021.
//  Copyright (c) 2021 marpies. All rights reserved.
//

import Foundation

protocol ConversationDetailsBusinessLogic {
	func loadConversation(request: ConversationDetails.Load.Request)
    func reloadConversation()
}

protocol ConversationDetailsDataStore {
	
}

class ConversationDetailsInteractor: ConversationDetailsBusinessLogic, ConversationDetailsDataStore, ConversationDetailsWorkerDelegate {

	var worker: ConversationDetailsWorker?

	var presenter: ConversationDetailsPresentationLogic?
	
	//
	// MARK: - Load conversation
	//
	
    func loadConversation(request: ConversationDetails.Load.Request) {
		self.worker?.delegate = self
		self.worker?.loadConversation(request: request)
	}
    
    //
    // MARK: - Reload conversation
    //
    
    func reloadConversation() {
        self.worker?.reloadConversation()
    }
    
    //
    // MARK: - Worker delegate
    //
    
    func conversationDidLoad(response: ConversationDetails.Load.Response) {
        self.presenter?.presentConversation(response: response)
    }
    
    func conversationLoadDidFail(response: ConversationDetails.LoadError.Response) {
        self.presenter?.presentLoadError(response: response)
    }
    
}
