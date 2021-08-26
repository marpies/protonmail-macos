//
//  KeyValueStore.swift
//  ProtonMailMac
//
//  Created by Marcel Piešťanský on 23.08.2021.
//

import Foundation

public protocol KeyValueStore {
    
    func string(forKey key: String) -> String?
    func setString(forKey key: String, value: String)
    
    func int(forKey key: String) -> Int?
    func setInt(forKey key: String, value: Int)
    
    func bool(forKey key: String) -> Bool?
    func setBool(forKey key: String, value: Bool)
    
    func data(forKey key: String) -> Data?
    func setData(forKey key: String, value: Data)
    
    func removeValue(forKey key: String)
    
    // Sugar
    
    func setString(forKey key: KeyValueStoreKey, value: String)
    func setInt(forKey key: KeyValueStoreKey, value: Int)
    func setBool(forKey key: KeyValueStoreKey, value: Bool)
    func setData(forKey key: KeyValueStoreKey, value: Data)
    func string(forKey key: KeyValueStoreKey) -> String?
    func int(forKey key: KeyValueStoreKey) -> Int?
    func bool(forKey key: KeyValueStoreKey) -> Bool?
    func data(forKey key: KeyValueStoreKey) -> Data?
    func removeValue(forKey key: KeyValueStoreKey)
    
}

public extension KeyValueStore {

    func setString(forKey key: KeyValueStoreKey, value: String) {
        self.setString(forKey: key.rawValue, value: value)
    }

    func setInt(forKey key: KeyValueStoreKey, value: Int) {
        self.setInt(forKey: key.rawValue, value: value)
    }

    func setBool(forKey key: KeyValueStoreKey, value: Bool) {
        self.setBool(forKey: key.rawValue, value: value)
    }

    func setData(forKey key: KeyValueStoreKey, value: Data) {
        self.setData(forKey: key.rawValue, value: value)
    }

    func string(forKey key: KeyValueStoreKey) -> String? {
        return self.string(forKey: key.rawValue)
    }

    func int(forKey key: KeyValueStoreKey) -> Int? {
        return self.int(forKey: key.rawValue)
    }

    func bool(forKey key: KeyValueStoreKey) -> Bool? {
        return self.bool(forKey: key.rawValue)
    }

    func data(forKey key: KeyValueStoreKey) -> Data? {
        return self.data(forKey: key.rawValue)
    }

    func removeValue(forKey key: KeyValueStoreKey) {
        return self.removeValue(forKey: key.rawValue)
    }

}
