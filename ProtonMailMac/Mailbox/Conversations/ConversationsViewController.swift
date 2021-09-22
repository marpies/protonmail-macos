//
//  ConversationsViewController.swift
//  ProtonMailMac
//
//  Created by Marcel Piešťanský on 16.09.2021.
//  Copyright (c) 2021 marpies. All rights reserved.
//

import AppKit

protocol ConversationsDisplayLogic: AnyObject {
    func displayConversations(viewModel: Conversations.LoadConversations.ViewModel)
    func displayConversationsUpdate(viewModel: Conversations.UpdateConversations.ViewModel)
    func displayConversationUpdate(viewModel: Conversations.UpdateConversation.ViewModel)
    func displayConversationsError(viewModel: Conversations.LoadError.ViewModel)
    func displayConversationsUpToDate()
    func displayLoadConversation(viewModel: Conversations.LoadConversation.ViewModel)
}

protocol ConversationsViewControllerDelegate: AnyObject {
    func conversationDidRequestLoad(conversationId: String)
}

class ConversationsViewController: NSViewController, ConversationsDisplayLogic, ConversationsViewDelegate {
	
	var interactor: ConversationsBusinessLogic?
	var router: (ConversationsRoutingLogic & ConversationsDataPassing)?

    private let mainView: ConversationsView = ConversationsView()
    
    weak var delegate: ConversationsViewControllerDelegate?
	
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
    // MARK: - Load messages
    //
    
    func loadConversations(labelId: String) {
        let request = Conversations.LoadConversations.Request(labelId: labelId)
        self.interactor?.loadConversations(request: request)
    }
    
    func displayConversations(viewModel: Conversations.LoadConversations.ViewModel) {
        self.mainView.displayConversations(viewModel: viewModel)
    }
    
    //
    // MARK: - Conversations update
    //
    
    func displayConversationsUpdate(viewModel: Conversations.UpdateConversations.ViewModel) {
        self.mainView.displayConversationsUpdate(viewModel: viewModel)
    }
    
    func displayConversationUpdate(viewModel: Conversations.UpdateConversation.ViewModel) {
        self.mainView.displayConversationUpdate(viewModel: viewModel)
    }
    
    //
    // MARK: - Conversations error
    //
    
    func displayConversationsError(viewModel: Conversations.LoadError.ViewModel) {
        self.mainView.displayConversationsError(viewModel: viewModel)
    }
    
    //
    // MARK: - Messages up to date
    //
    
    func displayConversationsUpToDate() {
        self.mainView.removeErrorView()
    }
    
    //
    // MARK: - Load conversation
    //
    
    func displayLoadConversation(viewModel: Conversations.LoadConversation.ViewModel) {
        self.delegate?.conversationDidRequestLoad(conversationId: viewModel.id)
    }
    
    //
    // MARK: - View delegate
    //
    
    func errorViewButtonDidTap() {
        self.mainView.removeErrorView()
        
        self.interactor?.processErrorViewButtonTap()
    }
    
    func conversationCellDidStarConversation(id: String) {
        let request: Conversations.UpdateConversationStar.Request = Conversations.UpdateConversationStar.Request(id: id, isOn: true)
        self.interactor?.updateConversationStar(request: request)
    }
    
    func conversationCellDidUnstarConversation(id: String) {
        let request: Conversations.UpdateConversationStar.Request = Conversations.UpdateConversationStar.Request(id: id, isOn: false)
        self.interactor?.updateConversationStar(request: request)
    }
    
    func messagesDidSelect(ids: [String]) {
        let request = Conversations.ConversationsDidSelect.Request(ids: ids)
        self.interactor?.processConversationsSelection(request: request)
    }
    
    func refreshMessagesButtonDidTap() {
        self.interactor?.processRefreshButtonTap()
    }
    
}
