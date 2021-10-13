//
//  MainInteractor.swift
//  ProtonMailMac
//
//  Created by Marcel Piešťanský on 25.08.2021.
//  Copyright (c) 2021 marpies. All rights reserved.
//

import Foundation

protocol MainBusinessLogic {
	func loadData(request: Main.Init.Request)
    func loadTitle(request: Main.LoadTitle.Request)
    func processMailboxSelectionUpdate(request: Main.MailboxSelectionDidUpdate.Request)
    func processSceneDidInitialize()
    func processToolbarAction(request: Main.ToolbarAction.Request)
}

protocol MainDataStore {
	
}

class MainInteractor: MainBusinessLogic, MainDataStore, MainWorkerDelegate {

    var worker: MainWorker?

	var presenter: MainPresentationLogic?
	
	//
	// MARK: - Load data
	//
	
	func loadData(request: Main.Init.Request) {
		self.worker?.delegate = self
		self.worker?.loadData(request: request)
	}
    
    //
    // MARK: - Load title
    //
    
    func loadTitle(request: Main.LoadTitle.Request) {
        self.worker?.loadTitle(request: request)
    }
    
    //
    // MARK: - Process mailbox selection update
    //
    
    func processMailboxSelectionUpdate(request: Main.MailboxSelectionDidUpdate.Request) {
        self.worker?.processMailboxSelectionUpdate(request: request)
    }
    
    //
    // MARK: - Process scene did initialize
    //
    
    func processSceneDidInitialize() {
        self.worker?.processSceneDidInitialize()
    }
    
    //
    // MARK: - Process toolbar action
    //
    
    func processToolbarAction(request: Main.ToolbarAction.Request) {
        self.worker?.processToolbarAction(request: request)
    }
    
    //
    // MARK: - Worker delegate
    //
    
    func mailboxDidLoad(response: Main.Init.Response) {
        self.presenter?.presentData(response: response)
    }
    
    func mailboxTitleDidLoad(response: Main.LoadTitle.Response) {
        self.presenter?.presentTitle(response: response)
    }
    
    func mailboxToolbarShouldUpdate(response: Main.UpdateToolbar.Response) {
        self.presenter?.presentToolbar(response: response)
    }
    
}
