//
//  SignInWorker.swift
//  ProtonMailMac
//
//  Created by Marcel Piešťanský on 25.08.2021.
//  Copyright (c) 2021 marpies. All rights reserved.
//

import Foundation
import Swinject

protocol SignInWorkerDelegate: AnyObject {
    func signInDidBegin()
    func signInDidFail(response: SignIn.SignInError.Response)
    func signInDidComplete()
    func signInDidCancel()
    func signInDidRequestTwoFactorAuth()
    func signInDidRequestHumanVerification(response: SignIn.DisplayCaptcha.Response)
}

class SignInWorker: SignInProcessingWorkerDelegate, ApiServiceHumanVerificationDelegate {
    
    private typealias TwoFactorContext = (credential: AuthCredential, passwordMode: PasswordMode)
    
    private let resolver: Resolver
    private let usersManager: UsersManager
    
    private var apiService: ApiService?
    private var tempAuthCredential: AuthCredential?
    
    private var twoFactorContext: TwoFactorContext?
    private var captchaPassCallback: (([String : Any], Bool) -> Void)?
    
    var signInWorker: SignInProcessing?

	weak var delegate: SignInWorkerDelegate?
    
    init(resolver: Resolver) {
        self.resolver = resolver
        self.usersManager = resolver.resolve(UsersManager.self)!
    }
    
    func signIn(request: SignIn.ProcessSignIn.Request) {
        // Check local errors (empty username, password)
        var localError: SignIn.SignInError.LocalError = []
        if request.username.isEmpty {
            localError.insert(.emptyUsername)
        }
        if request.password.isEmpty {
            localError.insert(.emptyPassword)
        }
        
        guard localError.isEmpty else {
            let response: SignIn.SignInError.Response = SignIn.SignInError.Response(localError: localError)
            self.delegate?.signInDidFail(response: response)
            return
        }
        
        self.delegate?.signInDidBegin()
        
        self.startSignIn(username: request.username, password: request.password)
    }
    
    func processTwoFactorInput(request: SignIn.TwoFactorInput.Request) {
        guard let context = self.twoFactorContext else { return }
        
        self.twoFactorContext = nil
        
        // A code was provided, continue with authentication
        if let code = request.code {
            self.signInWorker?.continueWithTwoFactorAuth(credential: context.credential, passwordMode: context.passwordMode, code: code)
        }
        // Cancelled
        else {
            self.processCancelledSignIn()
        }
    }
    
    func processCaptchaChallenge(request: SignIn.CaptchaChallengePass.Request) {
        guard let callback = self.captchaPassCallback else { return }
        
        self.captchaPassCallback = nil
        
        let headers: [String: String] = [
            "x-pm-human-verification-token": request.token,
            "x-pm-human-verification-token-type": "captcha"
        ]
        
        callback(headers, false)
    }
    
    func processCaptchaChallengeDidCancel() {
        guard let callback = self.captchaPassCallback else { return }
        
        self.captchaPassCallback = nil
        
        callback([:], true)
    }
    
    //
    // MARK: - Private
    //
    
    private func startSignIn(username: String, password: String) {
        guard self.signInWorker == nil else {
            fatalError("Unexpected application state.")
        }
        
        self.apiService = self.resolver.resolve(ApiService.self)!
        self.apiService?.humanVerifyDelegate = self
        
        self.signInWorker = self.resolver.resolve(SignInProcessing.self, arguments: username, password, self.apiService!)!
        self.signInWorker?.delegate = self
        self.signInWorker?.signIn()
    }
    
    private func revokeUnfinalizedSession() {
        guard let credential = self.tempAuthCredential else { return }
        
        self.tempAuthCredential = nil
        
        UserDataService(auth: credential).signOut { _ in
            
        }
    }
    
    private func processCancelledSignIn() {
        self.revokeUnfinalizedSession()
        
        self.signInWorker = nil
        self.apiService = nil
        
        #if DEBUG
        print("  sign in did cancel")
        #endif
        
        self.delegate?.signInDidCancel()
    }
    
    //
    // MARK: - Sign in processing worker delegate
    //
    
    func signInDidSucceed(userInfo: UserInfo, authCredential: AuthCredential) {
        self.signInWorker = nil
        self.apiService = nil
        
        self.usersManager.add(userInfo: userInfo, auth: authCredential)
        self.usersManager.save()
        self.usersManager.trackLogIn()
        
        self.delegate?.signInDidComplete()
    }
    
    func signInDidFail(error: SignIn.SignInError.RequestError) {
        // Revoke the session that may have been created
        self.revokeUnfinalizedSession()
        
        #if DEBUG
        print("  sign in did fail \(error)")
        #endif
        
        self.signInWorker = nil
        self.apiService = nil
        
        let response: SignIn.SignInError.Response = SignIn.SignInError.Response(requestError: error)
        self.delegate?.signInDidFail(response: response)
    }
    
    func authCredentialDidReceive(_ credential: AuthCredential) {
        self.tempAuthCredential = credential
    }
    
    func signInDidRequestTwoFactorAuth(credential: AuthCredential, passwordMode: PasswordMode) {
        // Store the credential / password mode until we receive the two-factor code
        self.twoFactorContext = TwoFactorContext(credential: credential, passwordMode: passwordMode)
        
        self.delegate?.signInDidRequestTwoFactorAuth()
    }
    
    func signInDidCancel() {
        self.processCancelledSignIn()
    }
    
    //
    // MARK: - Human verification
    //
    
    func verifyHuman(methods: [HumanVerificationMethod], startToken: String?, completion: @escaping ([String : Any], Bool) -> Void) {
        // todo support other methods if captcha not available
        
        self.captchaPassCallback = completion
        
        let response: SignIn.DisplayCaptcha.Response = SignIn.DisplayCaptcha.Response(startToken: startToken)
        self.delegate?.signInDidRequestHumanVerification(response: response)
    }

}
