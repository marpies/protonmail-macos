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
    
    func errorViewButtonDidTap() {
        self.mainView.showLoading()
        
        self.interactor?.reloadConversation()
    }
    
    func messageDetailDidClick(messageId: String) {
        // todo expand/collapse message + load content
    }
    
    func messageFavoriteStatusDidChange(messageId: String, isOn: Bool) {
        // todo update status
    }
    
    func conversationFavoriteStatusDidChange(isOn: Bool) {
        // todo update status
    }
    
}
