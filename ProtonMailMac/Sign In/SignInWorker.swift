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
}

class SignInWorker: SignInProcessingWorkerDelegate {
    
    private let resolver: Resolver
    private let usersManager: UsersManager
    
    private var tempAuthCredential: AuthCredential?
    
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
        if let credential = self.tempAuthCredential {
            
        }
        
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

}
