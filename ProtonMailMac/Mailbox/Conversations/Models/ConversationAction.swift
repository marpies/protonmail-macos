//
//  ConversationAction.swift
//  ProtonMailMac
//
//  Created by Marcel Piešťanský on 20.09.2021.
//  Copyright © 2021 marpies. All rights reserved.
//

import Foundation

enum ConversationAction: String {
    
    // Read/unread
    case read = "read"
    case unread = "unread"
    
    // Move mailbox
    case delete = "delete"
    
    case label = "applyLabel"
    case unlabel = "unapplyLabel"
    case folder = "moveToFolder"
}
