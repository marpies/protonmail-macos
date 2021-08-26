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
    
    var authCredential: AuthCredential? {get }
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
    
    var authCredential: AuthCredential? {
        return nil
    }
    
    var method: HTTPMethod {
        return .get
    }
    
    var parameters: [String: Any]? {
        return nil
    }
    
    func copyWithCredential(_ credential: AuthCredential) -> Self {
        fatalError("Must be overriden")
    }
}

private let v_default: Int = 3

public extension Request {
    var version: Int {
        return v_default
    }
}
