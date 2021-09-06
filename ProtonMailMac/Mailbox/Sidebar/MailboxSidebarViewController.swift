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
}

class MailboxSidebarViewController: NSViewController, MailboxSidebarDisplayLogic, MailboxSidebarViewDelegate {
	
	var interactor: MailboxSidebarBusinessLogic?
	var router: (MailboxSidebarRoutingLogic & MailboxSidebarDataPassing)?

    private let mainView: MailboxSidebarView = MailboxSidebarView()
	
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
	}
    
}
