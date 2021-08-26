//
//  File.swift
//  
//
//  Created by Marcel Piešťanský on 22.08.2021.
//

import Foundation

public struct ErrorResponse: Codable {
    public var code: Int
    public var error: String
    public var errorDescription: String
}
