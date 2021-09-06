//
//  MailboxSidebarInteractor.swift
//  ProtonMailMac
//
//  Created by Marcel Piešťanský on 27.08.2021.
//  Copyright (c) 2021 marpies. All rights reserved.
//

import Foundation

protocol MailboxSidebarBusinessLogic {
	func loadData(request: MailboxSidebar.Init.Request)
}

protocol MailboxSidebarDataStore {
	
}

class MailboxSidebarInteractor: MailboxSidebarBusinessLogic, MailboxSidebarDataStore, MailboxSidebarWorkerDelegate {

    var worker: MailboxSidebarWorker?

	var presenter: MailboxSidebarPresentationLogic?
	
	//
	// MARK: - Load data
	//
	
	func loadData(request: MailboxSidebar.Init.Request) {
		self.worker?.delegate = self
		self.worker?.loadData(request: request)
	}
    
    //
    // MARK: - Worker delegate
    //
    
    func mailboxSidebarDidLoad(response: MailboxSidebar.Init.Response) {
        self.presenter?.presentData(response: response)
    }
    
}
