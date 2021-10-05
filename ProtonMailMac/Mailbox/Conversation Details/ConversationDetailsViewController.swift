//
//  ConversationDetailsViewController.swift
//  ProtonMailMac
//
//  Created by Marcel Piešťanský on 17.09.2021.
//  Copyright (c) 2021 marpies. All rights reserved.
//

import AppKit

protocol ConversationDetailsDisplayLogic: AnyObject {
    func displayConversation(viewModel: ConversationDetails.Load.ViewModel)
    func displayLoadError(viewModel: ConversationDetails.LoadError.ViewModel)
    func displayMessageUpdate(viewModel: ConversationDetails.UpdateMessage.ViewModel)
    func displayConversationUpdate(viewModel: ConversationDetails.UpdateConversation.ViewModel)
    func displayMessageContentLoading(viewModel: ConversationDetails.MessageContentLoadDidBegin.ViewModel)
    func displayMessageContentLoaded(viewModel: ConversationDetails.MessageContentLoaded.ViewModel)
    func displayMessageContentCollapsed(viewModel: ConversationDetails.MessageContentCollapsed.ViewModel)
    func displayMessageContentError(viewModel: ConversationDetails.MessageContentError.ViewModel)
    func displayRemoteContentBox(viewModel: ConversationDetails.DisplayRemoteContentBox.ViewModel)
    func removeRemoteContentBox(viewModel: ConversationDetails.RemoveRemoteContentBox.ViewModel)
}

class ConversationDetailsViewController: NSViewController, ConversationDetailsDisplayLogic, ConversationDetailsViewDelegate {
	
	var interactor: ConversationDetailsBusinessLogic?
	var router: (ConversationDetailsRoutingLogic & ConversationDetailsDataPassing)?

    private let mainView: ConversationDetailsView = ConversationDetailsView()
	
	//	
	// MARK: - View lifecycle
	//
    
    override func loadView() {
        self.mainView.delegate = self
        self.view = self.mainView
    }
	
	override func viewDidLoad() {
		super.viewDidLoad()
	}
	
	//	
	// MARK: - Load conversation
	//
	
    func loadConversation(id: String) {
        self.mainView.showLoading()
        
        let request: ConversationDetails.Load.Request = ConversationDetails.Load.Request(id: id)
        self.interactor?.loadConversation(request: request)
	}
    
    //
    // MARK: - Display conversation
    //
    
    func displayConversation(viewModel: ConversationDetails.Load.ViewModel) {
        self.mainView.displayConversation(viewModel: viewModel)
    }
    
    //
    // MARK: - Display conversation error
    //
    
    func displayLoadError(viewModel: ConversationDetails.LoadError.ViewModel) {
        self.mainView.displayLoadError(viewModel: viewModel)
    }
    
    //
    // MARK: - Display message update
    //
    
    func displayMessageUpdate(viewModel: ConversationDetails.UpdateMessage.ViewModel) {
        self.mainView.displayMessageUpdate(viewModel: viewModel)
    }
    
    //
    // MARK: - Display conversation update
    //
    
    func displayConversationUpdate(viewModel: ConversationDetails.UpdateConversation.ViewModel) {
        self.mainView.displayConversationUpdate(viewModel: viewModel)
    }
    
    //
    // MARK: - Display message content loading
    //
    
    func displayMessageContentLoading(viewModel: ConversationDetails.MessageContentLoadDidBegin.ViewModel) {
        self.mainView.displayMessageContentLoading(viewModel: viewModel)
    }
    
    //
    // MARK: - Display message content loaded
    //
    
    func displayMessageContentLoaded(viewModel: ConversationDetails.MessageContentLoaded.ViewModel) {
        self.mainView.displayMessageContentLoaded(viewModel: viewModel)
    }
    
    //
    // MARK: - Display message content collapsed
    //
    
    func displayMessageContentCollapsed(viewModel: ConversationDetails.MessageContentCollapsed.ViewModel) {
        self.mainView.displayMessageContentCollapsed(viewModel: viewModel)
    }
    
    //
    // MARK: - Display message content error
    //
    
    func displayMessageContentError(viewModel: ConversationDetails.MessageContentError.ViewModel) {
        self.mainView.displayMessageContentError(viewModel: viewModel)
    }
    
    //
    // MARK: - Display remote content box
    //
    
    func displayRemoteContentBox(viewModel: ConversationDetails.DisplayRemoteContentBox.ViewModel) {
        self.mainView.displayRemoteContentBox(viewModel: viewModel)
    }
    
    //
    // MARK: - Remove remote content box
    //
    
    func removeRemoteContentBox(viewModel: ConversationDetails.RemoveRemoteContentBox.ViewModel) {
        self.mainView.removeRemoteContentBox(viewModel: viewModel)
    }
    
    //
    // MARK: - View delegate
    //
    
    func errorViewButtonDidTap() {
        self.mainView.showLoading()
        
        self.interactor?.reloadConversation()
    }
    
    func messageDetailDidClick(messageId: String) {
        let request: ConversationDetails.MessageClick.Request = ConversationDetails.MessageClick.Request(id: messageId)
        self.interactor?.processMessageClick(request: request)
    }
    
    func messageFavoriteStatusDidChange(messageId: String, isOn: Bool) {
        let request: ConversationDetails.UpdateMessageStar.Request = ConversationDetails.UpdateMessageStar.Request(id: messageId, isOn: isOn)
        self.interactor?.updateMessageStar(request: request)
    }
    
    func conversationFavoriteStatusDidChange(isOn: Bool) {
        let request: ConversationDetails.UpdateConversationStar.Request = ConversationDetails.UpdateConversationStar.Request(isOn: isOn)
        self.interactor?.updateConversationStar(request: request)
    }
    
    func messageRetryContentLoadButtonDidTap(messageId: String) {
        let request: ConversationDetails.RetryMessageContentLoad.Request = ConversationDetails.RetryMessageContentLoad.Request(id: messageId)
        self.interactor?.retryMessageContentLoad(request: request)
    }
    
    func messageRemoteContentButtonDidClick(messageId: String) {
        let request: ConversationDetails.RemoteContentButtonClick.Request = ConversationDetails.RemoteContentButtonClick.Request(messageId: messageId)
        self.interactor?.processRemoteContentButtonClick(request: request)
    }
    
}
