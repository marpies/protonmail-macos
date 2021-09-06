//
//  AuthCredentialRefreshing.swift
//  ProtonMailMac
//
//  Created by Marcel Piešťanský on 06.09.2021.
//  Copyright © 2021 marpies. All rights reserved.
//

import Foundation

/// Protocol extension that handles the "refresh session" request from the API service.
public protocol AuthCredentialRefreshing: ApiServiceAuthDelegate {
    var auth: AuthCredential? { get }
    var apiService: ApiService? { get }
    
    /// Called once the "refresh session" process is finishes successfully.
    /// Allows the objects conforming to this protocol to provide custom logic.
    func authCredentialDidRefresh()
}

public extension AuthCredentialRefreshing {
    
    func refreshSession(completion:  @escaping (_ auth: AuthCredential?, _ error: NSError?) -> Void) {
        // Refresh access token if needed
        if let auth = self.auth, auth.isExpired {
            let sessionId: String = auth.sessionID
            
            let request: AuthRefreshRequest = AuthRefreshRequest(authCredential: auth)
            self.apiService?.request(request) { (result: Result<AuthRefreshResponse, Error>) in
                switch result {
                case .success(let response):
                    let credential = AuthCredential(sessionID: sessionId, accessToken: response.accessToken, refreshToken: response.refreshToken, expiration: Date(timeIntervalSinceNow: response.expiresIn), privateKey: nil, passwordKeySalt: nil)
                    self.updateAuth(auth: credential)
                    
                    completion(credential, nil)
                case .failure(let err):
                    self.processRefreshTokenError(err as NSError, completion: completion)
                }
            }
            
            return
        }
        
        // Use the existing access token
        completion(self.auth, nil)
    }
    
    //
    // MARK: - Private
    //
    
    private func processRefreshTokenError(_ error: NSError, completion: (AuthCredential?, NSError?) -> Void) {
        completion(nil, error)
        
        if error.code == 422 {
            self.sessionDidRevoke()
        }
    }
    
    private func updateAuth(auth: AuthCredential) {
        self.auth?.update(sessionID: auth.sessionID, accessToken: auth.accessToken, refreshToken: auth.refreshToken, expiration: auth.expiration)
        
        self.authCredentialDidRefresh()
    }
    
}
