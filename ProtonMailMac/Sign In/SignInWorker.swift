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
}

class SignInWorker: SignInProcessingWorkerDelegate {
    
    private typealias TwoFactorContext = (credential: AuthCredential, passwordMode: PasswordMode)
    
    private let resolver: Resolver
    private let usersManager: UsersManager
    
    private var tempAuthCredential: AuthCredential?
    
    private var twoFactorContext: TwoFactorContext?
    
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
    
    //
    // MARK: - Private
    //
    
    private func startSignIn(username: String, password: String) {
        guard self.signInWorker == nil else {
            fatalError("Unexpected application state.")
        }
        
        self.signInWorker = resolver.resolve(SignInProcessing.self, arguments: username, password)!
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
        
        self.delegate?.signInDidCancel()
    }
    
    //
    // MARK: - Sign in processing worker delegate
    //
    
    func signInDidSucceed(userInfo: UserInfo, authCredential: AuthCredential) {
        self.signInWorker = nil
        
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

}
