//
//  MessagesViewController.swift
//  ProtonMailMac
//
//  Created by Marcel Piešťanský on 05.09.2021.
//  Copyright (c) 2021 marpies. All rights reserved.
//

import AppKit

protocol MessagesDisplayLogic: AnyObject {
    
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
    
}
