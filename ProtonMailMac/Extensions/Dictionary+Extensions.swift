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
    
    func getBool(_ key: String) -> Bool? {
        return self[key] as? Bool
    }
    
}
