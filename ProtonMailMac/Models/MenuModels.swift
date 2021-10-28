//
//  MenuModels.swift
//  ProtonMailMac
//
//  Created by Marcel Piešťanský on 27.10.2021.
//  Copyright © 2021 marpies. All rights reserved.
//

import Foundation
import AppKit

enum MenuItemIdentifier {
    case any
    case copyAddress(email: String)
}

enum MenuItem {
    
    case separator
    case item(id: MenuItemIdentifier, title: String, color: NSColor?, state: NSControl.StateValue?, icon: String?, children: [MenuItem]?, isEnabled: Bool)
    
}
