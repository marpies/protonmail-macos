//
//  File.swift
//  
//
//  Created by Marcel Piešťanský on 22.08.2021.
//

import Foundation

public struct AddressesRequest: Request {
    public var path: String {
        return AddressesAPI.path
    }
    
    public let authCredential : AuthCredential?

    public init(authCredential : AuthCredential?) {
        self.authCredential  = authCredential
    }
    
    public let isAuth: Bool = true
}
