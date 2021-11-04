//
//  File.swift
//  
//
//  Created by Marcel Piešťanský on 22.08.2021.
//

import Foundation
import AFNetworking

public struct PMApiService: ApiService {
    
    public let sessionManager: AFHTTPSessionManager
    public weak var authDelegate: ApiServiceAuthDelegate?
    public weak var humanVerifyDelegate: ApiServiceHumanVerificationDelegate?

    public init() {
        self.sessionManager = SessionManager.shared.sessionManager
    }
}
