//
//  WebSignInInteractor.swift
//  ProtonMailMac
//
//  Created by Marcel Piešťanský on 04.11.2021.
//  Copyright (c) 2021 marpies. All rights reserved.
//

import Foundation

protocol WebSignInBusinessLogic {
	func loadData(request: WebSignIn.Init.Request)
    func processCookies(request: WebSignIn.ProcessCookies.Request)
    func processPassword(request: WebSignIn.ProcessPassword.Request)
    func processSignInErrorAlertConfirmation(request: WebSignIn.SignInErrorAlertConfirmation.Request)
}

protocol WebSignInDataStore {
    /// True if the sign in sheet can be dismissed manually with UI.
    var isDismissable: Bool { get set }
}

class WebSignInInteractor: WebSignInBusinessLogic, WebSignInDataStore, WebSignInWorkerDelegate {

	var worker: WebSignInWorker?

	var presenter: WebSignInPresentationLogic?
	
    var isDismissable: Bool = false
    
	//
	// MARK: - Load data
	//
	
	func loadData(request: WebSignIn.Init.Request) {
        self.worker?.isDismissable = self.isDismissable
		self.worker?.delegate = self
		self.worker?.loadData(request: request)
	}
    
    //
    // MARK: - Process cookies
    //
    
    func processCookies(request: WebSignIn.ProcessCookies.Request) {
        self.worker?.processCookies(request: request)
    }
    
    //
    // MARK: - Process password
    //
    
    func processPassword(request: WebSignIn.ProcessPassword.Request) {
        self.worker?.processPassword(request: request)
    }
    
    //
    // MARK: - Process sign in error alert confirmation
    //
    
    func processSignInErrorAlertConfirmation(request: WebSignIn.SignInErrorAlertConfirmation.Request) {
        self.worker?.processSignInErrorAlertConfirmation(request: request)
    }
    
    //
    // MARK: - Worker delegate
    //
    
    func webSignInDidLoad(response: WebSignIn.Init.Response) {
        self.presenter?.presentData(response: response)
    }
    
    func webSignInShouldClearCookies(response: WebSignIn.ClearCookies.Response) {
        self.presenter?.presentClearCookies(response: response)
    }
    
    func webSignInDidObtainAuthCredentials() {
        self.presenter?.presentSignInFinalizing()
    }
    
    func webSignInDidComplete() {
        self.presenter?.presentSignInDidComplete()
    }
    
    func webSignInDidFail(response: WebSignIn.SignInError.Response) {
        self.presenter?.presentSignInError(response: response)
    }
    
}
