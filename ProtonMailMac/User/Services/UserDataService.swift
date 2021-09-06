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

public class UserDataService: AuthCredentialRefreshing {
    
    public let auth: AuthCredential?
    
    public private(set) var apiService: ApiService?
    
    public weak var delegate: UserDataServiceDelegate?

    public init(auth: AuthCredential) {
        self.auth = auth
        self.apiService = PMApiService()
        self.apiService?.authDelegate = self
    }
    
    public func signOut(completion: @escaping (Error?) -> Void) {
        let request = AuthDeleteRequest()
        
        self.apiService?.request(request) { (_, _, err) in
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
    
    public func sessionDidRevoke() {
        self.handleRevokedSession()
    }
    
    public func onForceUpgrade() {
        // todo
    }
    
    public func authCredentialDidRefresh() {
        self.delegate?.authDidUpdate()
    }
    
    //
    // MARK: - Private
    //
    
    private func handleRevokedSession() {
        // todo user session revoked
    }
    
}
