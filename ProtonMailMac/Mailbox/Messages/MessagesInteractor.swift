//
//  MessagesInteractor.swift
//  ProtonMailMac
//
//  Created by Marcel Piešťanský on 05.09.2021.
//  Copyright (c) 2021 marpies. All rights reserved.
//

import Foundation

protocol MessagesBusinessLogic {
	func loadMessages(request: Messages.LoadMessages.Request)
    func processErrorViewButtonTap()
    func starMessage(request: Messages.StarMessage.Request)
    func unstarMessage(request: Messages.UnstarMessage.Request)
}

protocol MessagesDataStore {
	
}

class MessagesInteractor: MessagesBusinessLogic, MessagesDataStore, MessagesWorkerDelegate {

	var worker: MessagesWorker?

	var presenter: MessagesPresentationLogic?
	
	//
	// MARK: - Load messages
	//
	
	func loadMessages(request: Messages.LoadMessages.Request) {
		self.worker?.delegate = self
		self.worker?.loadMessages(request: request)
	}
    
    //
    // MARK: - Process error view button tap
    //
    
    func processErrorViewButtonTap() {
        self.worker?.reloadMessages()
    }
    
    //
    // MARK: - Star / unstar message
    //
    
    func starMessage(request: Messages.StarMessage.Request) {
        self.worker?.starMessage(request: request)
    }
    
    func unstarMessage(request: Messages.UnstarMessage.Request) {
        self.worker?.unstarMessage(request: request)
    }
    
    //
    // MARK: - Worker delegate
    //
    
    func messagesDidLoad(response: Messages.LoadMessages.Response) {
        self.presenter?.presentMessages(response: response)
    }
    
    func messagesDidUpdate(response: Messages.UpdateMessages.Response) {
        self.presenter?.presentMessagesUpdate(response: response)
    }
    
    func messageDidUpdate(response: Messages.UpdateMessage.Response) {
        self.presenter?.presentMessageUpdate(response: response)
    }
    
    func messagesLoadDidFail(response: Messages.LoadError.Response) {
        self.presenter?.presentMessagesError(response: response)
    }
    
    func messagesDidUpdateWithoutChange() {
        self.presenter?.presentMessagesUpToDate()
    }
    
}
