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
    func updateMessageStar(request: ConversationDetails.UpdateMessageStar.Request)
    func updateConversationStar(request: ConversationDetails.UpdateConversationStar.Request)
    func processMessageClick(request: ConversationDetails.MessageClick.Request)
    func retryMessageContentLoad(request: ConversationDetails.RetryMessageContentLoad.Request)
    func processRemoteContentButtonClick(request: ConversationDetails.RemoteContentButtonClick.Request)
    func processContactMenuItemTap(request: ConversationDetails.ContactMenuItemTap.Request)
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
    // MARK: - Update message star
    //
    
    func updateMessageStar(request: ConversationDetails.UpdateMessageStar.Request) {
        self.worker?.updateMessageStar(request: request)
    }
    
    //
    // MARK: - Update conversation star
    //
    
    func updateConversationStar(request: ConversationDetails.UpdateConversationStar.Request) {
        self.worker?.updateConversationStar(request: request)
    }
    
    //
    // MARK: - Process message click
    //
    
    func processMessageClick(request: ConversationDetails.MessageClick.Request) {
        self.worker?.processMessageClick(request: request)
    }
    
    //
    // MARK: - Retry message content load
    //
    
    func retryMessageContentLoad(request: ConversationDetails.RetryMessageContentLoad.Request) {
        self.worker?.retryMessageContentLoad(request: request)
    }
    
    //
    // MARK: - Process remote content button click
    //
    
    func processRemoteContentButtonClick(request: ConversationDetails.RemoteContentButtonClick.Request) {
        self.worker?.processRemoteContentButtonClick(request: request)
    }
    
    //
    // MARK: - Process menu item tap
    //
    
    func processContactMenuItemTap(request: ConversationDetails.ContactMenuItemTap.Request) {
        self.worker?.processContactMenuItemTap(request: request)
    }
    
    //
    // MARK: - Worker delegate
    //
    
    func conversationLoadDidBegin() {
        self.presenter?.presentConversationLoadDidBegin()
    }
    
    func conversationDidLoad(response: ConversationDetails.Load.Response) {
        self.presenter?.presentConversation(response: response)
    }
    
    func conversationLoadDidFail(response: ConversationDetails.LoadError.Response) {
        self.presenter?.presentLoadError(response: response)
    }
    
    func conversationMessageDidUpdate(response: ConversationDetails.UpdateMessage.Response) {
        self.presenter?.presentMessageUpdate(response: response)
    }
    
    func conversationDidUpdate(response: ConversationDetails.UpdateConversation.Response) {
        self.presenter?.presentConversationUpdate(response: response)
    }
    
    func conversationMessageBodyLoadDidBegin(response: ConversationDetails.MessageContentLoadDidBegin.Response) {
        self.presenter?.presentMessageContentLoading(response: response)
    }
    
    func conversationMessageBodyDidLoad(response: ConversationDetails.MessageContentLoaded.Response) {
        self.presenter?.presentMessageContentLoaded(response: response)
    }
    
    func conversationMessageBodyCollapse(response: ConversationDetails.MessageContentCollapsed.Response) {
        self.presenter?.presentMessageContentCollapsed(response: response)
    }
    
    func conversationMessageBodyLoadDidFail(response: ConversationDetails.MessageContentError.Response) {
        self.presenter?.presentMessageContentError(response: response)
    }
    
    func conversationMessageRemoteContentBoxShouldAppear(response: ConversationDetails.DisplayRemoteContentBox.Response) {
        self.presenter?.presentRemoteContentBox(response: response)
    }
    
    func conversationMessageRemoteContentBoxShouldDisappear(response: ConversationDetails.RemoveRemoteContentBox.Response) {
        self.presenter?.removeRemoteContentBox(response: response)
    }
    
}
