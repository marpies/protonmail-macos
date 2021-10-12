//
//  ConversationsViewController.swift
//  ProtonMailMac
//
//  Created by Marcel Piešťanský on 16.09.2021.
//  Copyright (c) 2021 marpies. All rights reserved.
//

import AppKit

protocol ConversationsDisplayLogic: AnyObject {
    func displayItems(viewModel: Conversations.LoadItems.ViewModel)
    func displayItemsUpdate(viewModel: Conversations.UpdateItems.ViewModel)
    func displayItemUpdate(viewModel: Conversations.UpdateItem.ViewModel)
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
        let request = Conversations.LoadItems.Request(labelId: labelId)
        self.interactor?.loadItems(request: request)
    }
    
    func displayItems(viewModel: Conversations.LoadItems.ViewModel) {
        self.mainView.displayItems(viewModel: viewModel)
    }
    
    //
    // MARK: - Items update
    //
    
    func displayItemsUpdate(viewModel: Conversations.UpdateItems.ViewModel) {
        self.mainView.displayItemsUpdate(viewModel: viewModel)
    }
    
    func displayItemUpdate(viewModel: Conversations.UpdateItem.ViewModel) {
        self.mainView.displayItemUpdate(viewModel: viewModel)
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
    
    func conversationCellDidStarConversation(id: String, type: Conversations.TableItem.Kind) {
        let request: Conversations.UpdateItemStar.Request = Conversations.UpdateItemStar.Request(id: id, isOn: true, type: type)
        self.interactor?.updateItemStar(request: request)
    }
    
    func conversationCellDidUnstarConversation(id: String, type: Conversations.TableItem.Kind) {
        let request: Conversations.UpdateItemStar.Request = Conversations.UpdateItemStar.Request(id: id, isOn: false, type: type)
        self.interactor?.updateItemStar(request: request)
    }
    
    func itemsDidSelect(ids: [String], type: Conversations.TableItem.Kind) {
        let request = Conversations.ItemsDidSelect.Request(ids: ids, type: type)
        self.interactor?.processItemsSelection(request: request)
    }
    
    func refreshMessagesButtonDidTap() {
        self.interactor?.processRefreshButtonTap()
    }
    
}
