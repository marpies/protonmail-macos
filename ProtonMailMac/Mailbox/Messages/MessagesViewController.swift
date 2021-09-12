//
//  MessagesViewController.swift
//  ProtonMailMac
//
//  Created by Marcel Piešťanský on 05.09.2021.
//  Copyright (c) 2021 marpies. All rights reserved.
//

import AppKit

protocol MessagesDisplayLogic: AnyObject {
	func displayMessages(viewModel: Messages.LoadMessages.ViewModel)
    func displayMessagesUpdate(viewModel: Messages.UpdateMessages.ViewModel)
    func displayMessagesError(viewModel: Messages.LoadError.ViewModel)
    func displayMessagesUpToDate()
}

class MessagesViewController: NSViewController, MessagesDisplayLogic, MessagesViewDelegate {
	
	var interactor: MessagesBusinessLogic?
	var router: (MessagesRoutingLogic & MessagesDataPassing)?

    private let mainView: MessagesView = MessagesView()
	
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
	
    func loadMessages(labelId: String) {
		let request = Messages.LoadMessages.Request(labelId: labelId)
		self.interactor?.loadMessages(request: request)
	}
	
	func displayMessages(viewModel: Messages.LoadMessages.ViewModel) {
        self.mainView.displayMessages(viewModel: viewModel)
	}
    
    //
    // MARK: - Messages update
    //
    
    func displayMessagesUpdate(viewModel: Messages.UpdateMessages.ViewModel) {
        self.mainView.displayMessagesUpdate(viewModel: viewModel)
    }
    
    //
    // MARK: - Messages error
    //
    
    func displayMessagesError(viewModel: Messages.LoadError.ViewModel) {
        self.mainView.displayMessagesError(viewModel: viewModel)
    }
    
    //
    // MARK: - Messages up to date
    //
    
    func displayMessagesUpToDate() {
        self.mainView.removeErrorView()
    }
    
    //
    // MARK: - View delegate
    //
    
    func errorViewButtonDidTap() {
        self.mainView.removeErrorView()
        
        self.interactor?.processErrorViewButtonTap()
    }
    
}
