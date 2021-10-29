//
//  MailboxViewController.swift
//  ProtonMailMac
//
//  Created by Marcel Piešťanský on 16.09.2021.
//  Copyright (c) 2021 marpies. All rights reserved.
//

import AppKit

protocol MailboxDisplayLogic: AnyObject {
    func displayItems(viewModel: Mailbox.LoadItems.ViewModel)
    func displayItemsUpdate(viewModel: Mailbox.UpdateItems.ViewModel)
    func displayItemUpdate(viewModel: Mailbox.UpdateItem.ViewModel)
    func displayMailboxError(viewModel: Mailbox.LoadError.ViewModel)
    func displayMailboxUpToDate()
    func displayLoadConversation(viewModel: Mailbox.LoadConversation.ViewModel)
    func displayItemsSelection(viewModel: Mailbox.ItemsDidSelect.ViewModel)
    func displayItemsRefresh(viewModel: Mailbox.RefreshItems.ViewModel)
}

protocol MailboxViewControllerDelegate: AnyObject {
    func mailboxSceneDidInitialize()
    func mailboxSelectionDidUpdate(viewModel: Mailbox.ItemsDidSelect.ViewModel)
    func conversationDidRequestLoad(conversationId: String)
}

class MailboxViewController: NSViewController, MailboxDisplayLogic, MailboxViewDelegate {
	
	var interactor: MailboxBusinessLogic?
	var router: (MailboxRoutingLogic & MailboxDataPassing)?
    
    private var isInitialLoad: Bool = true

    private let mainView: MailboxView = MailboxView()
    
    weak var delegate: MailboxViewControllerDelegate?
	
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
    
    func loadMailbox(labelId: String) {
        let request = Mailbox.LoadItems.Request(labelId: labelId)
        self.interactor?.loadItems(request: request)
    }
    
    func displayItems(viewModel: Mailbox.LoadItems.ViewModel) {
        self.mainView.displayItems(viewModel: viewModel)
        
        if self.isInitialLoad {
            self.isInitialLoad = false
            
            self.delegate?.mailboxSceneDidInitialize()
        }
    }
    
    //
    // MARK: - Items update
    //
    
    func displayItemsUpdate(viewModel: Mailbox.UpdateItems.ViewModel) {
        self.mainView.displayItemsUpdate(viewModel: viewModel)
    }
    
    func displayItemUpdate(viewModel: Mailbox.UpdateItem.ViewModel) {
        self.mainView.displayItemUpdate(viewModel: viewModel)
    }
    
    //
    // MARK: - Mailbox error
    //
    
    func displayMailboxError(viewModel: Mailbox.LoadError.ViewModel) {
        self.mainView.displayMailboxError(viewModel: viewModel)
    }
    
    //
    // MARK: - Messages up to date
    //
    
    func displayMailboxUpToDate() {
        self.mainView.removeErrorView()
    }
    
    //
    // MARK: - Load conversation
    //
    
    func displayLoadConversation(viewModel: Mailbox.LoadConversation.ViewModel) {
        self.delegate?.conversationDidRequestLoad(conversationId: viewModel.id)
    }
    
    //
    // MARK: - Items selection
    //
    
    func displayItemsSelection(viewModel: Mailbox.ItemsDidSelect.ViewModel) {
        self.delegate?.mailboxSelectionDidUpdate(viewModel: viewModel)
    }
    
    //
    // MARK: - Items refresh
    //
    
    func displayItemsRefresh(viewModel: Mailbox.RefreshItems.ViewModel) {
        self.mainView.displayItemsRefresh(viewModel: viewModel)
    }
    
    //
    // MARK: - View delegate
    //
    
    func errorViewButtonDidTap() {
        self.mainView.removeErrorView()
        
        self.interactor?.processErrorViewButtonTap()
    }
    
    func mailboxCellDidStarItem(id: String, type: Mailbox.TableItem.Kind) {
        let request: Mailbox.UpdateItemStar.Request = Mailbox.UpdateItemStar.Request(id: id, isOn: true, type: type)
        self.interactor?.updateItemStar(request: request)
    }
    
    func mailboxCellDidUnstarItem(id: String, type: Mailbox.TableItem.Kind) {
        let request: Mailbox.UpdateItemStar.Request = Mailbox.UpdateItemStar.Request(id: id, isOn: false, type: type)
        self.interactor?.updateItemStar(request: request)
    }
    
    func itemsDidSelect(ids: [String], type: Mailbox.TableItem.Kind) {
        let request = Mailbox.ItemsDidSelect.Request(ids: ids, type: type)
        self.interactor?.processItemsSelection(request: request)
    }
    
    func itemsDidDeselect() {
        self.interactor?.processItemsDeselection()
    }
    
}
