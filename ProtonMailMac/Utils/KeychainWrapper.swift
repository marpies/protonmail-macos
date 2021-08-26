//
//  KeychainWrapper.swift
//  ProtonMailMac
//
//  Created by Marcel Piešťanský on 23.08.2021.
//

import Foundation
import PMKeymaker

final class KeychainWrapper: Keychain {
    
    public static var keychain = KeychainWrapper()
    
    init() {
        let prefix = "Q6T2359V7Q."
        let group = prefix + "com.marpies.ProtonMailMac"
        let service = "com.marpies"
        
        super.init(service: service, accessGroup: group)
    }
}
