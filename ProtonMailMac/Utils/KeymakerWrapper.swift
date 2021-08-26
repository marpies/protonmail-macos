//
//  Keymaker.swift
//  ProtonMailMac
//
//  Created by Marcel Piešťanský on 23.08.2021.
//

import Foundation
import PMKeymaker

public final class KeymakerWrapper {
    
    private let keyValueStore: KeyValueStore
    private let keymaker: Keymaker
    
    public init(keyValueStore: KeyValueStore, settingsProvider: SettingsProvider) {
        self.keyValueStore = keyValueStore
        self.keymaker = Keymaker(autolocker: Autolocker(lockTimeProvider: settingsProvider), keychain: KeychainWrapper.keychain)
    }
    
    public var mainKey: PMKeymaker.Key? {
        return self.keymaker.mainKey
    }
    
    public func resetAutolock() {
        self.keymaker.resetAutolock()
    }
    
    public func wipeMainKey() {
        self.keymaker.wipeMainKey()
    }
    
    @discardableResult
    public func mainKeyExists() -> Bool {
        return self.keymaker.mainKeyExists()
    }
    
    public func lockTheApp() {
        self.keymaker.lockTheApp()
    }
    
    public func obtainMainKey(with protector: ProtectionStrategy, handler: @escaping (PMKeymaker.Key?) -> Void) {
        return self.keymaker.obtainMainKey(with: protector, handler: handler)
    }
    
    public func activate(_ protector: ProtectionStrategy, completion: @escaping (Bool) -> Void) {
        return self.keymaker.activate(protector, completion: completion)
    }
    
    public func isProtectorActive<T: ProtectionStrategy>(_ protectionType: T.Type) -> Bool {
        return self.keymaker.isProtectorActive(protectionType)
    }
    
    @discardableResult
    public func deactivate(_ protector: ProtectionStrategy) -> Bool {
        return self.keymaker.deactivate(protector)
    }
    
}
