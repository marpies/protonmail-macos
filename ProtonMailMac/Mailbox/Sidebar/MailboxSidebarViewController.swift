//
//  MailboxSidebarViewController.swift
//  ProtonMailMac
//
//  Created by Marcel Piešťanský on 27.08.2021.
//  Copyright (c) 2021 marpies. All rights reserved.
//

import AppKit

protocol MailboxSidebarDisplayLogic: AnyObject {
	func displayData(viewModel: MailboxSidebar.Init.ViewModel)
    func displayGroupsRefresh(viewModel: MailboxSidebar.RefreshGroups.ViewModel)
    func displayItemsBadgeUpdate(viewModel: MailboxSidebar.ItemsBadgeUpdate.ViewModel)
}

protocol MailboxSidebarViewControllerDelegate: AnyObject {
    func mailboxSidebarDidInitialize()
    func mailboxSidebarDidSelectLabel(id: String)
}

class MailboxSidebarViewController: NSViewController, MailboxSidebarDisplayLogic, MailboxSidebarViewDelegate {
	
	var interactor: MailboxSidebarBusinessLogic?
	var router: (MailboxSidebarRoutingLogic & MailboxSidebarDataPassing)?
    
    private var isInitialLoad: Bool = true

    private let mainView: MailboxSidebarView = MailboxSidebarView()
    
    weak var delegate: MailboxSidebarViewControllerDelegate?
	
	//	
	// MARK: - View lifecycle
	//
    
    override func loadView() {
        self.mainView.delegate = self
        self.view = self.mainView
    }
	
	override func viewDidLoad() {
		super.viewDidLoad()

		self.loadData()
	}
	
	//	
	// MARK: - Load data
	//
	
	private func loadData() {
		let request = MailboxSidebar.Init.Request()
		self.interactor?.loadData(request: request)
	}
	
	func displayData(viewModel: MailboxSidebar.Init.ViewModel) {
        self.mainView.displayData(viewModel: viewModel)
        
        if self.isInitialLoad {
            self.isInitialLoad = false
            
            self.delegate?.mailboxSidebarDidInitialize()
        }
	}
    
    //
    // MARK: - Groups refresh
    //
    
    func displayGroupsRefresh(viewModel: MailboxSidebar.RefreshGroups.ViewModel) {
        self.mainView.displayGroupsRefresh(viewModel: viewModel)
    }
    
    //
    // MARK: - Items badge update
    //
    
    func displayItemsBadgeUpdate(viewModel: MailboxSidebar.ItemsBadgeUpdate.ViewModel) {
        self.mainView.displayItemsBadgeUpdate(viewModel: viewModel)
    }
    
    //
    // MARK: - View delegate
    //
    
    func mailboxSidebarDidSelectItem(_ item: MailboxSidebar.Item.ViewModel) {
        let request = MailboxSidebar.ItemSelected.Request(id: item.id)
        self.interactor?.processSelectedItem(request: request)
        
        self.delegate?.mailboxSidebarDidSelectLabel(id: item.id)
    }
    
}
