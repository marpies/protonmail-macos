//
//  TwoFARequest.swift
//  ProtonMailMac
//
//  Created by Marcel Piešťanský on 26.08.2021.
//  Copyright © 2021 marpies. All rights reserved.
//

import Foundation

struct TwoFARequest: Request {
    
    let path: String = AuthAPI.path + "/2fa"
    let method: HTTPMethod = .post
    let isAuth: Bool = true
    let autoRetry: Bool = false
    var authCredential: AuthCredential?
    
    var parameters: [String: Any]? {
        return  [
            "TwoFactorCode": code
        ]
    }
    
    let code: String
    
    init(code: String, authCredential: AuthCredential)  {
        self.code = code
        self.authCredential = authCredential
    }
}
