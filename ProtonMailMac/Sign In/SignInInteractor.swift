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
    func processCaptchaChallenge(request: SignIn.CaptchaChallengePass.Request)
    func processCaptchaChallengeDidCancel()
}

protocol SignInDataStore {
    /// True if the sign in sheet can be dismissed manually with UI.
    var isDismissable: Bool { get set }
    
    var captchaStartToken: String? { get }
}

class SignInInteractor: SignInBusinessLogic, SignInDataStore, SignInWorkerDelegate {

    var worker: SignInWorker?

	var presenter: SignInPresentationLogic?
    
    var isDismissable: Bool = false
    
    private(set) var captchaStartToken: String?
	
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
    // MARK: - Captcha challenge passed
    //
    
    func processCaptchaChallenge(request: SignIn.CaptchaChallengePass.Request) {
        self.worker?.processCaptchaChallenge(request: request)
    }

    //
    // MARK: - Captcha challenge did cancel
    //
    
    func processCaptchaChallengeDidCancel() {
        self.worker?.processCaptchaChallengeDidCancel()
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
    
    func signInDidRequestHumanVerification(response: SignIn.DisplayCaptcha.Response) {
        self.captchaStartToken = response.startToken
        
        self.presenter?.presentCaptcha()
    }
    
}
