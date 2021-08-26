//
//  SignInProcessingWorker.swift
//  ProtonMailMac
//
//  Created by Marcel Piešťanský on 25.08.2021.
//  Copyright © 2021 marpies. All rights reserved.
//

import Foundation
import Crypto

protocol SignInProcessingWorkerDelegate: AnyObject {
    func authCredentialDidReceive(_ credential: AuthCredential)
    func signInDidFail(error: SignIn.SignInError.RequestError)
    func signInDidSucceed(userInfo: UserInfo, authCredential: AuthCredential)
}

protocol SignInProcessing {
    var delegate: SignInProcessingWorkerDelegate? { get set }
    
    init(username: String, password: String)
    
    func signIn()
}

/// Worker that handles the actual sign in process.
struct SignInProcessingWorker: SignInProcessing {
    
    private let apiService: ApiService
    
    private let username: String
    private let password: String
    
    weak var delegate: SignInProcessingWorkerDelegate?

    init(username: String, password: String) {
        self.username = username
        self.password = password
        self.apiService = PMApiService()
    }
    
    func signIn() {
        let request = AuthInfoRequest(username: self.username)
        self.apiService.request(request, completion: { (authInfo: AuthInfoResponse) in
            guard authInfo.error == nil,
                  let srpSession = authInfo.srpSession,
                  let srpClient = self.getSrpProofs(authInfo: authInfo) else {
                self.failWithError(.serverError)
                return
            }
            
            guard let clientEphemeral = srpClient.clientEphemeral,
                  let clientProof = srpClient.clientProof,
                  let expectedServerProof = srpClient.expectedServerProof else
            {
                self.failWithError(.keysFailure)
                return
            }
            
            let request = AuthRequest(username: self.username, ephemeral: clientEphemeral, proof: clientProof, session: srpSession)
            
            self.apiService.request(request, completion: { (result: Swift.Result<AuthResponse, Error>) in
                switch result {
                case .success(let response):
                    // Check expected server proof
                    guard expectedServerProof == Data(base64Encoded: response.serverProof) else {
                        self.failWithError(.serverError)
                        return
                    }
                    
                    // are we done yet or need 2FA?
                    switch response._2FA.enabled {
                    case .off:
                        let credential = Credential(res: response)
                        
                        print(" Session ID: \(credential.UID)")
                        
                        self.processCredential(credential, passwordMode: response.passwordMode)
                    case .on:
//                        let credential = Credential(res: response)
//                        self.apiService.setSessionUID(uid: credential.UID)
//                        let context = (credential, response.passwordMode)
//                        completion(.success(.ask2FA(context)))
                        fatalError("Unexpected application state.")
                    case .u2f, .otp:
                        self.failWithError(.unsupported2FAOption)
                    }
                    
                case .failure(let err as NSError):
                    if self.isUnprocessableEntityError(err) {
                        self.failWithError(.incorrectCredentials)
                    } else {
                        self.failWithError(.serverError)
                    }
                }
            })
        })
    }
    
    //
    // MARK: - Private
    //
    
    /// Returns `true` if the given error represents an "unprocessable entity" error, e.g. incorrect login credentials.
    private func isUnprocessableEntityError(_ error: NSError) -> Bool {
        for pair in error.userInfo {
            guard let response = error.userInfo[pair.key] as? HTTPURLResponse else { continue }
            
            if response.statusCode == 422 {
                return true
            }
        }
        return false
    }
    
    private func getSrpProofs(authInfo: AuthInfoResponse) -> SrpProofs? {
        do {
            guard let salt = authInfo.salt,
                  let signedModulus = authInfo.modulus,
                  let serverEphemeral = authInfo.serverEphemeral else {
                return nil
            }
            
            let passSlic = self.password.data(using: .utf8)
            guard let auth = SrpAuth.init(authInfo.version,
                                          username: self.username,
                                          password: passSlic,
                                          b64salt: salt,
                                          signedModulus: signedModulus,
                                          serverEphemeral: serverEphemeral)
            else {
                return nil
            }
            
            // client SRP
            return try auth.generateProofs(2048)
        } catch {
            return nil
        }
    }
    
    private func processCredential(_ credential: Credential, passwordMode: PasswordMode) {
        let authCredential = AuthCredential(credential)
        
        // Provide the auth credential to the delegate in case we want to revoke the session
        // due an error later on before we actually manage to fully authenticate the user
        self.delegate?.authCredentialDidReceive(authCredential)
        
        let request = KeySaltsRequest(authCredential: authCredential)
        self.apiService.request(request, completion: { (salts: KeySaltResponse) in
            if salts.error != nil {
                self.failWithError(.serverError)
                return
            }
            
            let request = UserInfoRequest(authCredential: authCredential)
            self.apiService.request(request, completion: { (response: UserInfoResponse) in
                if response.error != nil {
                    self.failWithError(.serverError)
                    return
                }
                
                guard let user = response.userInfo,
                      let salt = salts.keySalt,
                      let privateKey = user.getPrivateKey(by: salts.keyID) else {
                    self.failWithError(.keysFailure)
                    return
                }
                
                let result: Result<String, SignIn.SignInError.RequestError> = self.processUserInfo(userInfo: user, keySalt: salt, privateKey: privateKey, credential: authCredential, passwordMode: passwordMode)
                
                switch result {
                case .success(let mpwd):
                    authCredential.update(password: mpwd)
                    
                    // Fetch user info and addresses
                    self.fetchUserInfo(authCredential: authCredential, userInfo: user)
                case .failure(let error):
                    self.failWithError(error)
                }
            })
        })
    }
    
    private func processUserInfo(userInfo: UserInfo?, keySalt: String?, privateKey: String?, credential: AuthCredential, passwordMode: PasswordMode) -> Result<String, SignIn.SignInError.RequestError> {
        credential.update(salt: keySalt, privateKey: privateKey)
        
        if passwordMode == .one {
            guard let keysalt: Data = keySalt?.decodeBase64() else {
                return .failure(.keysFailure)
            }
            
            let mpwd: String = PasswordUtils.getMailboxPassword(self.password, salt: keysalt)
            
            return .success(mpwd)
        }
        
        // todo this eventually calls requestMailboxPassword closure provided to SignInManager
        // and routing to kDecryptMailboxSegue in SignInVC
        // todo make this unsupported case for now (mailbox pwd was second password for decrypt keys for old accounts)
        // now only one password necessary
        return .failure(.unsupportedPasswordMode)
    }
    
    private func fetchUserInfo(authCredential: AuthCredential, userInfo: UserInfo) {
        let addressesReq = AddressesRequest(authCredential: authCredential)
        
        self.apiService.request(addressesReq, completion: { (response: AddressesResponse) in
            if response.error != nil {
                self.failWithError(.serverError)
            } else {
                userInfo.set(addresses: response.addresses)
                
                self.userDidAuthenticate(userInfo: userInfo, authCredential: authCredential)
            }
        })
    }
    
    private func userDidAuthenticate(userInfo: UserInfo, authCredential: AuthCredential) {
        // Check user delinquent status
        if userInfo.delinquent >= 3 {
            self.failWithError(.userDelinquent)
            return
        }
        
        // Success
        DispatchQueue.main.async {
            self.delegate?.signInDidSucceed(userInfo: userInfo, authCredential: authCredential)
        }
    }
    
    private func failWithError(_ error: SignIn.SignInError.RequestError) {
        DispatchQueue.main.async {
            self.delegate?.signInDidFail(error: error)
        }
    }
    
}
