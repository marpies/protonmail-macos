//
//  SignInInteractor.swift
//  ProtonMailMac
//
//  Created by Marcel Piešťanský on 25.08.2021.
//  Copyright (c) 2021 marpies. All rights reserved.
//

import Foundation

protocol SignInBusinessLogic {
	func initScene(request: SignIn.Init.Request)
    func signIn(request: SignIn.ProcessSignIn.Request)
    func processTwoFactorInput(request: SignIn.TwoFactorInput.Request)
}

protocol SignInDataStore {
    /// True if the sign in sheet can be dismissed manually with UI.
    var isDismissable: Bool { get set }
}

class SignInInteractor: SignInBusinessLogic, SignInDataStore, SignInWorkerDelegate {

    var worker: SignInWorker?

	var presenter: SignInPresentationLogic?
    
    var isDismissable: Bool = false
	
	//
	// MARK: - Init scene
	//
	
	func initScene(request: SignIn.Init.Request) {
		self.worker?.delegate = self
		
        let response = SignIn.Init.Response(isDismissable: self.isDismissable)
        self.presenter?.presentSignIn(response: response)
	}
    
    //
    // MARK: - Sign in
    //
    
    func signIn(request: SignIn.ProcessSignIn.Request) {
        self.worker?.signIn(request: request)
    }
    
    //
    // MARK: - Two-factor input
    //
    
    func processTwoFactorInput(request: SignIn.TwoFactorInput.Request) {
        self.worker?.processTwoFactorInput(request: request)
    }
    
    //
    // MARK: - Worker delegate
    //
    
    func signInDidBegin() {
        self.presenter?.presentSignInDidBegin()
    }
    
    func signInDidFail(response: SignIn.SignInError.Response) {
        self.presenter?.presentSignInError(response: response)
    }
    
    func signInDidComplete() {
        self.presenter?.presentSignInDidComplete()
    }
    
    func signInDidRequestTwoFactorAuth() {
        self.presenter?.presentTwoFactorInput()
    }
    
    func signInDidCancel() {
        self.presenter?.presentSignInDidCancel()
    }
    
}
