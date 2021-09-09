//
//  KeyValueStoreKeys.swift
//  ProtonMailMac
//
//  Created by Marcel Piešťanský on 26.08.2021.
//  Copyright © 2021 marpies. All rights reserved.
//

import Foundation

public enum KeyValueStoreKey: String {
    case autolockTime
    
    /// Encrypted array of AuthCredential.
    case authData
    
    /// Encrypted array of UserInfo.
    case usersInfo
    
    /// Tracks whether at least one user is logged in.
    case isLoggedIn
    
    /// Session id for the primary user.
    case primaryUserSessionId
    
    /// Last selected label id in the sidebar.
    case lastLabelId
}
