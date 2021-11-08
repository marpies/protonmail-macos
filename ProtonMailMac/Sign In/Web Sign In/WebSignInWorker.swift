//
//  WebSignInWorker.swift
//  ProtonMailMac
//
//  Created by Marcel Piešťanský on 04.11.2021.
//  Copyright (c) 2021 marpies. All rights reserved.
//

import Foundation
import Swinject

protocol WebSignInWorkerDelegate: AnyObject {
    func webSignInDidLoad(response: WebSignIn.Init.Response)
    func webSignInShouldClearCookies(response: WebSignIn.ClearCookies.Response)
    func webSignInDidObtainAuthCredentials()
    func webSignInDidFail(response: WebSignIn.SignInError.Response)
    func webSignInDidComplete()
}

class WebSignInWorker: SignInProcessingWorkerDelegate {

	private let resolver: Resolver
    
    /// Number of times we received the cookies response.
    /// We should only process the cookies on the second response.
    private var numCookieResponses: Int = 0
    
    // Captured data
    private var password: String?
    private var passwordMode: PasswordMode?
    private var authCookie: HTTPCookie?
    private var refreshCookie: HTTPCookie?
    
    private var apiService: ApiService?
    private var signInWorker: SignInProcessing?
    private var tempAuthCredential: AuthCredential?
    
    
    var isDismissable: Bool = false

	weak var delegate: WebSignInWorkerDelegate?

	init(resolver: Resolver) {
		self.resolver = resolver
	}

	func loadData(request: WebSignIn.Init.Request) {
        guard let url = self.getUrl() else { return }
        
        let response: WebSignIn.Init.Response = WebSignIn.Init.Response(url: url, javaScript: self.injectionScript, isDismissable: self.isDismissable)
        self.delegate?.webSignInDidLoad(response: response)
	}
    
    func processCookies(request: WebSignIn.ProcessCookies.Request) {
        self.numCookieResponses += 1
        
        guard self.numCookieResponses == 2 else { return }
        
        let domain: String = "protonmail"
        
        // Get the latest AUTH and REFRESH cookies and parse access/refresh tokens and session id
        for cookie in request.cookies {
            if cookie.domain.contains(domain) {
                if cookie.name.starts(with: "AUTH-") {
                    self.processAuthCookie(cookie)
                } else if cookie.name.starts(with: "REFRESH-") {
                    self.processRefreshCookie(cookie)
                }
            }
        }
        
        // We can clear cookies now
        let response = WebSignIn.ClearCookies.Response(domain: domain)
        self.delegate?.webSignInShouldClearCookies(response: response)
        
        if let value = self.refreshCookie?.value.removingPercentEncoding,
           let expiration = self.authCookie?.expiresDate,
           let accessToken = self.authCookie?.value,
           let json = value.parseObjectAny(),
           let refreshToken = json.getString("RefreshToken"),
           let uid = json.getString("UID"),
           let password = self.password,
           let passwordMode = self.passwordMode {
            self.delegate?.webSignInDidObtainAuthCredentials()
            
            let credential: AuthCredential = AuthCredential(sessionID: uid, accessToken: accessToken, refreshToken: refreshToken, expiration: expiration, privateKey: nil, passwordKeySalt: nil)
            
            self.apiService = self.resolver.resolve(ApiService.self)!
            
            // Username does not matter, we just want to obtain salts and keys for the credential we already have
            self.signInWorker = self.resolver.resolve(SignInProcessing.self, arguments: "", password, self.apiService!)!
            self.signInWorker?.delegate = self
            self.signInWorker?.processCredential(credential, passwordMode: passwordMode)
        } else {
            self.signInDidFail(error: .serverError)
        }
    }
    
    func processPassword(request: WebSignIn.ProcessPassword.Request) {
        self.password = request.password
        self.passwordMode = PasswordMode(rawValue: request.passwordMode)
    }
    
    func processSignInErrorAlertConfirmation(request: WebSignIn.SignInErrorAlertConfirmation.Request) {
        // Show web view again
        guard let url = self.getUrl() else { return }
        
        let response: WebSignIn.Init.Response = WebSignIn.Init.Response(url: url, javaScript: self.injectionScript, isDismissable: self.isDismissable)
        self.delegate?.webSignInDidLoad(response: response)
    }
    
    //
    // MARK: - Sign in processing delegate
    //
    
    func signInDidSucceed(userInfo: UserInfo, authCredential: AuthCredential) {
        self.signInWorker = nil
        self.apiService = nil
        self.tempAuthCredential = nil
        self.password = nil
        self.passwordMode = nil
        self.authCookie = nil
        self.refreshCookie = nil
        
        let usersManager: UsersManager = resolver.resolve(UsersManager.self)!
        usersManager.add(userInfo: userInfo, auth: authCredential)
        usersManager.save()
        usersManager.trackLogIn()
        
        self.delegate?.webSignInDidComplete()
    }
    
    func signInDidFail(error: SignIn.SignInError.RequestError) {
        // Revoke the session that may have been created
        self.revokeUnfinalizedSession()
        
        #if DEBUG
        print("  sign in did fail \(error)")
        #endif
        
        self.signInWorker = nil
        self.apiService = nil
        self.numCookieResponses = 0
        self.password = nil
        self.passwordMode = nil
        self.authCookie = nil
        self.refreshCookie = nil
        
        let response: WebSignIn.SignInError.Response = WebSignIn.SignInError.Response(error: error)
        self.delegate?.webSignInDidFail(response: response)
    }
    
    func authCredentialDidReceive(_ credential: AuthCredential) {
        self.tempAuthCredential = credential
    }
    
    func signInDidRequestTwoFactorAuth(credential: AuthCredential, passwordMode: PasswordMode) {
        // unused in this context
    }
    
    func signInDidCancel() {
        // unused in this context
    }
    
    //
    // MARK: - Private
    //
    
    private var injectionScript: String {
        return """
            const {fetch: origFetch} = window;
            window.fetch = async (...args) => {
                console.log("fetch called with args:", args);
                const response = await origFetch(...args);
                
                for (var i = 0; i < args.length; i++) {
                    const arg = args[i]
                    if (arg.href && arg.pathname) {
                        console.log(" fetch request to path: " + arg.pathname)
                        
                        // Get tokens from /cookies endpoint
                        if (arg.pathname === "/api/auth/cookies") {
                            window.webkit.messageHandlers.url_requests.postMessage("pm_cookie_response");
                        }
                        // Get password and password mode from /auth endpoint
                        else if (arg.pathname === "/api/auth") {
                            const clone = response.clone()
                            clone
                                .json()
                                .then(body => {
                                    if (body.PasswordMode) {
                                        const passwordMode = body.PasswordMode;
                                        const password = document.getElementById("password").value;
            
                                        window.webkit.messageHandlers.url_requests.postMessage({"password": password, "passwordMode": passwordMode});
                                    }
                                })
                                .catch(err => console.error(err));
                        }
                    
                        break
                    }
                }
                
                return response;
            }
            """
    }
    
    private func getUrl() -> URLRequest? {
        let urlRaw: String = "https://account.protonmail.com/login"
        
        guard let url = URL(string: urlRaw) else { return nil }
        
        return URLRequest(url: url)
    }
    
    private func processAuthCookie(_ cookie: HTTPCookie) {
        if let existing = self.authCookie {
            if let existingExpiration = existing.expiresDate, let newExpiration = cookie.expiresDate {
                // Use the newer cookie
                if existingExpiration < newExpiration {
                    self.authCookie = cookie
                }
            } else {
                self.authCookie = cookie
            }
        } else {
            self.authCookie = cookie
        }
    }
    
    private func processRefreshCookie(_ cookie: HTTPCookie) {
        if let existing = self.refreshCookie {
            if let existingExpiration = existing.expiresDate, let newExpiration = cookie.expiresDate {
                // Use the newer cookie
                if existingExpiration < newExpiration {
                    self.refreshCookie = cookie
                }
            } else {
                self.refreshCookie = cookie
            }
        } else {
            self.refreshCookie = cookie
        }
    }
    
    private func revokeUnfinalizedSession() {
        guard let credential = self.tempAuthCredential else { return }
        
        self.tempAuthCredential = nil
        
        UserDataService(auth: credential).signOut { _ in
            
        }
    }

}
