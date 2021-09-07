//
//  Dictionary+Extensions.swift
//  ProtonMailMac
//
//  Created by Marcel Piešťanský on 29.08.2021.
//  Copyright © 2021 marpies. All rights reserved.
//

import Foundation

extension Dictionary where Key == String, Value == Any {
    
    func getString(_ key: String) -> String? {
        return self[key] as? String
    }
    
    func getInt(_ key: String) -> Int? {
        return self[key] as? Int
    }
    
    func getDouble(_ key: String) -> Double? {
        return self[key] as? Double
    }
    
    func getBool(_ key: String) -> Bool? {
        return self[key] as? Bool
    }
    
    func getJson(_ key: String) -> [String: Any]? {
        return self[key] as? [String: Any]
    }
    
    func getJsonArray(_ key: String) -> [[String: Any]]? {
        return self[key] as? [[String: Any]]
    }
    
    func getArray<T>(_ key: String) -> [T]? {
        return self[key] as? [T]
    }
    
    func toJsonString() -> String? {
        if let data = try? JSONSerialization.data(withJSONObject: self, options: []),
           let value = String(data: data, encoding: .utf8) {
            return value
        }
        return nil
    }
    
}
