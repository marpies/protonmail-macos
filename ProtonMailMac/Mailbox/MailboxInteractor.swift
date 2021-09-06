//
//  MailboxInteractor.swift
//  ProtonMailMac
//
//  Created by Marcel Piešťanský on 25.08.2021.
//  Copyright (c) 2021 marpies. All rights reserved.
//

import Foundation

protocol MailboxBusinessLogic {
	func loadData(request: Mailbox.Init.Request)
}

protocol MailboxDataStore {
	
}

class MailboxInteractor: MailboxBusinessLogic, MailboxDataStore, MailboxWorkerDelegate {

    var worker: MailboxWorker?

	var presenter: MailboxPresentationLogic?
	
	//
	// MARK: - Load data
	//
	
	func loadData(request: Mailbox.Init.Request) {
		self.worker?.delegate = self
		self.worker?.loadData(request: request)
	}
    
    //
    // MARK: - Worker delegate
    //
    
    func mailboxDidLoad(response: Mailbox.Init.Response) {
        self.presenter?.presentData(response: response)
    }
    
}
