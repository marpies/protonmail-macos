//
//  UserDataService.swift
//  ProtonMailMac
//
//  Created by Marcel Piešťanský on 23.08.2021.
//

import Foundation

public protocol UserDataServiceDelegate: AnyObject {
    func authDidUpdate()
}

public class UserDataService: ApiServiceAuthDelegate {
    
    public let auth: AuthCredential
    
    private var apiService: ApiService
    
    public weak var delegate: UserDataServiceDelegate?

    public init(auth: AuthCredential) {
        self.auth = auth
        self.apiService = PMApiService()
        self.apiService.authDelegate = self
    }
    
    public func signOut(completion: @escaping (Error?) -> Void) {
        let request = AuthDeleteRequest()
        
        self.apiService.request(request) { (_, _, err) in
            if let error = err {
                completion(error)
            } else {
                completion(nil)
            }
        }
    }
    
    //
    // MARK: - Auth delegate
    //
    
    public func refreshSession(completion:  @escaping (_ auth: AuthCredential?, _ error: NSError?) -> Void) {
        let sessionId: String = self.auth.sessionID
        
        // Refresh access token if needed
        if self.auth.isExpired {
            let request: AuthRefreshRequest = AuthRefreshRequest(authCredential: self.auth)
            self.apiService.request(request) { (result: Result<AuthRefreshResponse, Error>) in
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
    
    public func sessionDidRevoke() {
        self.handleRevokedSession()
    }
    
    public func onForceUpgrade() {
        // todo
    }
    
    //
    // MARK: - Private
    //
    
    private func processRefreshTokenError(_ error: NSError, completion: (AuthCredential?, NSError?) -> Void) {
        completion(nil, error)
        
        if error.code == 422 {
            self.handleRevokedSession()
        }
    }
    
    private func updateAuth(auth: AuthCredential) {
        self.auth.update(sessionID: auth.sessionID, accessToken: auth.accessToken, refreshToken: auth.refreshToken, expiration: auth.expiration)
        
        self.delegate?.authDidUpdate()
    }
    
    private func handleRevokedSession() {
        // todo user session revoked
    }
    
}
