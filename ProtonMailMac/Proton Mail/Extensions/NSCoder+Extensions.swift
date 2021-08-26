//
//  NSCoder+Extensions.swift
//  ProtonMailMac
//
//  Created by Marcel Piešťanský on 22.08.2021.
//

import Foundation

extension NSCoder {
    
    func decodeStringForKey(_ key: String) -> String? {
        return decodeObject(forKey: key) as? String
    }
    
}
