//
//  DefaultKeyValueStore.swift
//  ProtonMailMac
//
//  Created by Marcel Piešťanský on 23.08.2021.
//

import Foundation
import PMKeymaker

struct DefaultKeyValueStore: KeyValueStore, SettingsProvider {
    
    private let userDefaults: UserDefaults
    
    init() {
        self.userDefaults = UserDefaults.standard
    }
    
    //
    // MARK: - Settings provider
    //
    
    var lockTime: AutolockTimeout {
        get {
            if let value = self.int(forKey: .autolockTime) {
                return AutolockTimeout(rawValue: value)
            }
            return .always
        }
        
        set {
            self.setInt(forKey: .autolockTime, value: newValue.rawValue)
            
            // todo keymaker.resetAutolock()
        }
    }
    
    //
    // MARK: - Key value store
    //
    
    func string(forKey key: String) -> String? {
        return self.userDefaults.string(forKey: key)
    }
    
    func setString(forKey key: String, value: String) {
        self.userDefaults.setValue(value, forKey: key)
    }
    
    func int(forKey key: String) -> Int? {
        return self.userDefaults.integer(forKey: key)
    }
    
    func setInt(forKey key: String, value: Int) {
        self.userDefaults.setValue(value, forKey: key)
    }
    
    func bool(forKey key: String) -> Bool? {
        return self.userDefaults.value(forKey: key) as? Bool
    }
    
    func setBool(forKey key: String, value: Bool) {
        self.userDefaults.setValue(value, forKey: key)
    }
    
    func data(forKey key: String) -> Data? {
        self.userDefaults.data(forKey: key)
    }
    
    func setData(forKey key: String, value: Data) {
        self.userDefaults.setValue(value, forKey: key)
    }
    
    func removeValue(forKey key: String) {
        self.userDefaults.removeObject(forKey: key)
    }
    
}
