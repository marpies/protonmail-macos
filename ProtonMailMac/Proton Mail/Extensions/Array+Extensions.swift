//
//  Array+Extensions.swift
//  ProtonMailMac
//
//  Created by Marcel Piešťanský on 22.08.2021.
//

import Foundation
import Crypto

public extension Array where Element : Key {
    func archive() -> Data {
        return try! NSKeyedArchiver.archivedData(withRootObject: self, requiringSecureCoding: false)
    }
    
    var binPrivKeys : Data {
        var out = Data()
        var error : NSError?
        for key in self {
            if let privK = ArmorUnarmor(key.private_key, &error) {
                out.append(privK)
            }
        }
        return out
    }
    
    var binPrivKeysArray: [Data] {
        var out: [Data] = []
        var error: NSError?
        for key in self {
            if let privK = ArmorUnarmor(key.private_key, &error) {
                out.append(privK)
            }
        }
        return out
    }
    
    var newSchema : Bool {
        for key in self {
            if key.newSchema {
                return true
            }
        }
        return false
    }
    
}

public extension Array where Element: Address {
    func defaultAddress() -> Address? {
        for addr in self {
            if addr.status == 1 && addr.receive == 1 {
                return addr
            }
        }
        return nil
    }
    
    func defaultSendAddress() -> Address? {
        for addr in self {
            if addr.status == 1 && addr.receive == 1 && addr.send == 1 {
                return addr
            }
        }
        return nil
    }
    
    func indexOfAddress(_ addressid: String) -> Address? {
        for addr in self {
            if addr.status == 1 && addr.receive == 1 && addr.address_id == addressid {
                return addr
            }
        }
        return nil
    }
    
    func getAddressOrder() -> [String] {
        let ids = self.map { $0.address_id }
        return ids
    }
    
    func getAddressNewOrder() -> [Int] {
        let ids = self.map { $0.order }
        return ids
    }
    
    func toKeys() -> [Key] {
        var out_array = [Key]()
        for i in 0 ..< self.count {
            let addr = self[i]
            for k in addr.keys {
                out_array.append(k)
            }
        }
        return out_array
    }
}
