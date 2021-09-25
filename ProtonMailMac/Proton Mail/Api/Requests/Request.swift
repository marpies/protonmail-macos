//
//  File.swift
//  
//
//  Created by Marcel Piešťanský on 22.08.2021.
//

import Foundation

public protocol Package {
    var parameters: [String: Any]? { get }
}

public protocol Request: Package {
    var version: Int { get }
    var path: String { get }
    var headers: [String: Any] { get }
    var method: HTTPMethod { get }
    
    var isAuth: Bool { get }
    
    var authCredential: AuthCredential? { get set }
    var autoRetry: Bool { get }
    
    func copyWithCredential(_ credential: AuthCredential) -> Self
}

public extension Request {
    var isAuth: Bool {
        return true
    }
    
    var autoRetry: Bool {
        return true
    }
    
    var headers: [String: Any] {
        return [:]
    }
    
    var method: HTTPMethod {
        return .get
    }
    
    var parameters: [String: Any]? {
        return nil
    }
    
    func copyWithCredential(_ credential: AuthCredential) -> Self {
        var copy: Self = self
        let newCredential: AuthCredential = copy.authCredential ?? credential
        newCredential.update(sessionID: credential.sessionID, accessToken: credential.accessToken, refreshToken: credential.refreshToken, expiration: credential.expiration)
        copy.authCredential = newCredential
        return copy
    }
}

private let v_default: Int = 3

public extension Request {
    var version: Int {
        return v_default
    }
}


public protocol DownloadRequest: Request {
    
    var destinationURL: URL { get }
    
}
