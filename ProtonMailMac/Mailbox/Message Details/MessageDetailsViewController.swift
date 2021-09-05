//
//  MessageDetailsViewController.swift
//  ProtonMailMac
//
//  Created by Marcel Piešťanský on 05.09.2021.
//  Copyright (c) 2021 marpies. All rights reserved.
//

import AppKit

protocol MessageDetailsDisplayLogic: AnyObject {
	func displayData(viewModel: MessageDetails.Init.ViewModel)
}

class MessageDetailsViewController: NSViewController, MessageDetailsDisplayLogic, MessageDetailsViewDelegate {
	
	var interactor: MessageDetailsBusinessLogic?
	var router: (MessageDetailsRoutingLogic & MessageDetailsDataPassing)?

    private let mainView: MessageDetailsView = MessageDetailsView()
	
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
		let request = MessageDetails.Init.Request()
		self.interactor?.loadData(request: request)
	}
	
	func displayData(viewModel: MessageDetails.Init.ViewModel) {
        self.mainView.displayData(viewModel: viewModel)
	}
    
}
