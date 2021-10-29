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

protocol MenuItemParsing {
    func getMenuItem(model: MenuItem) -> NSMenuItem
    func getMenuItem(model: MenuItem, target: AnyObject?, selector: Selector?) -> NSMenuItem
}

extension MenuItemParsing {
    
    func getMenuItem(model: MenuItem) -> NSMenuItem {
        return self.getMenuItem(model: model, target: nil, selector: nil)
    }
    
    func getMenuItem(model: MenuItem, target: AnyObject?, selector: Selector?) -> NSMenuItem {
        switch model {
        case .separator:
            return NSMenuItem.separator()
        case .item(let id, let title, let color, let state, let icon, let children, let isEnabled):
            let item: IdentifiedNSMenuItem = IdentifiedNSMenuItem()
            item.title = title
            item.itemId = id
            item.isEnabled = isEnabled
            
            if let state = state {
                item.state = state
            }
            
            if let icon = icon {
                if #available(macOS 11.0, *) {
                    item.image = NSImage(systemSymbolName: icon, accessibilityDescription: nil)?.tinted(color: color)
                } else {
                    // todo fallback icon
                }
            }
            
            if let children = children {
                item.submenu = NSMenu().with { menu in
                    menu.items = children.map { self.getMenuItem(model: $0, target: target, selector: selector) }
                }
            }
            
            if isEnabled, let target = target, let selector = selector {
                item.target = target
                item.action = selector
            }
            
            return item
        }
    }
    
}
