//
//  File.swift
//  
//
//  Created by Marcel Piešťanský on 22.08.2021.
//

import Foundation
import AFNetworking

public struct SessionManager: ApiUrlInjected {
    
    public static let shared: SessionManager = SessionManager()
    
    public private(set) var sessionManager: AFHTTPSessionManager!
    
    public init() {
        self.sessionManager = AFHTTPSessionManager(baseURL: URL(string: self.apiUrl)!)
        self.sessionManager.requestSerializer = AFJSONRequestSerializer()
        self.sessionManager.requestSerializer.cachePolicy = NSURLRequest.CachePolicy.reloadIgnoringCacheData  // .ReloadIgnoringCacheData
        self.sessionManager.requestSerializer.stringEncoding = String.Encoding.utf8.rawValue
        
        self.sessionManager.responseSerializer.acceptableContentTypes?.insert("text/html")
        self.sessionManager.securityPolicy.allowInvalidCertificates = false
        self.sessionManager.securityPolicy.validatesDomainName = false
        
        self.sessionManager.setSessionDidReceiveAuthenticationChallenge { _, challenge, credential in
            print("   AUTH CHALLENGE!!")
            
            var dispositionToReturn: URLSession.AuthChallengeDisposition = .performDefaultHandling
            // Hard force to pass all connections -- this only for testing and with charles
            let credentialOut = URLCredential(trust: challenge.protectionSpace.serverTrust!)
            credential?.pointee = credentialOut
            dispositionToReturn = .useCredential
            
            return dispositionToReturn
        }
    }
    
}
