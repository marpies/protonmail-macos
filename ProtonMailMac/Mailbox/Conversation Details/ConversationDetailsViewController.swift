//
//  ConversationDetailsViewController.swift
//  ProtonMailMac
//
//  Created by Marcel Piešťanský on 17.09.2021.
//  Copyright (c) 2021 marpies. All rights reserved.
//

import AppKit

protocol ConversationDetailsDisplayLogic: AnyObject {
	func displayData(viewModel: ConversationDetails.Init.ViewModel)
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

		self.loadData()
	}
	
	//	
	// MARK: - Load data
	//
	
	private func loadData() {
		let request = ConversationDetails.Init.Request()
		self.interactor?.loadData(request: request)
	}
	
	func displayData(viewModel: ConversationDetails.Init.ViewModel) {
        self.mainView.displayData(viewModel: viewModel)
	}
    
}
