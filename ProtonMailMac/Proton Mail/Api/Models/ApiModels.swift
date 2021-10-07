//
//  File.swift
//  
//
//  Created by Marcel Piešťanský on 22.08.2021.
//

import Foundation

enum ApiUrl {
    
    static let `protocol`: String = "https"
    static let host: String = "mail.protonmail.com"
    
    static let prefix: String = "mail/v4"
    
}

public protocol ApiUrlInjected {
    var apiUrl: String { get }
    
    func getApiUrl(path: String) -> String
}

public extension ApiUrlInjected {
    
    var apiUrl: String {
        return "\(ApiUrl.protocol)://\(ApiUrl.host)/api"
    }
    
    func getApiUrl(path: String) -> String {
        return "\(self.apiUrl)/\(path)"
    }
    
}
