//
//  Array+JSON.swift
//  ProtonMailMac
//
//  Created by Marcel Piešťanský on 06.09.2021.
//  Copyright © 2021 marpies. All rights reserved.
//

import Foundation

extension Array where Element == [String: Any] {
    
    func toJsonString() -> String? {
        if let data = try? JSONSerialization.data(withJSONObject: self, options: []),
           let value = String(data: data, encoding: .utf8) {
            return value
        }
        return nil
    }
    
}
