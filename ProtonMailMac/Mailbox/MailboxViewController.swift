//
//  MailboxViewController.swift
//  ProtonMailMac
//
//  Created by Marcel Piešťanský on 25.08.2021.
//  Copyright (c) 2021 marpies. All rights reserved.
//

import AppKit

protocol MailboxDisplayLogic: AnyObject {
	func displayData(viewModel: Mailbox.Init.ViewModel)
}

class MailboxViewController: NSSplitViewController, MailboxDisplayLogic, ToolbarUtilizing {
	
	var interactor: MailboxBusinessLogic?
	var router: (MailboxRoutingLogic & MailboxDataPassing)?
    
    weak var toolbarDelegate: ToolbarUtilizingDelegate?

	//
	// MARK: - Object lifecycle
	//
	
	override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
		super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
		
		self.setup()
	}
	
	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		
		self.setup()
	}
	
	//	
	// MARK: - Setup
	//
	
	private func setup() {
		let viewController = self
		let interactor = MailboxInteractor()
		let presenter = MailboxPresenter()
		let router = MailboxRouter()
		viewController.interactor = interactor
		viewController.router = router
		interactor.presenter = presenter
		presenter.viewController = viewController
		router.viewController = viewController
		router.dataStore = interactor
	}
	
	//	
	// MARK: - View lifecycle
	//
	
	override func viewDidLoad() {
		super.viewDidLoad()

		self.loadData()
	}
	
	//	
	// MARK: - Load data
	//
	
	private func loadData() {
		let request = Mailbox.Init.Request()
		self.interactor?.loadData(request: request)
	}
	
	func displayData(viewModel: Mailbox.Init.ViewModel) {
        
	}
    
}
