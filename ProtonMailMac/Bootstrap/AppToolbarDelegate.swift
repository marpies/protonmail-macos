//
//  AppToolbarDelegate.swift
//  ProtonMailMac
//
//  Created by Marcel Piešťanský on 09.10.2021.
//  Copyright © 2021 marpies. All rights reserved.
//

import Foundation
import AppKit

class AppToolbarDelegate: NSObject, NSToolbarDelegate, ToolbarUtilizingDelegate {
    
    private var toolbarItems: [NSToolbarItem]?
    private var itemIdentifiers: [NSToolbarItem.Identifier]?
    
    var window: NSWindow?
    
    let toolbar: NSToolbar
    
    init(toolbar: NSToolbar) {
        self.toolbar = toolbar
        
        super.init()
        
        self.toolbar.delegate = self
    }
    
    //
    // MARK: - Toolbar utilizing delegate
    //
    
    func toolbarTitleDidUpdate(title: String, subtitle: String?) {
        self.window?.title = title
        
        if #available(macOS 11.0, *), let subtitle = subtitle {
            self.window?.subtitle = subtitle
        }
    }
    
    func toolbarItemsDidUpdate(identifiers: [NSToolbarItem.Identifier], items: [NSToolbarItem]) {
        // Remove existing items
        while !self.toolbar.items.isEmpty {
            let index: Int = self.toolbar.items.count - 1
            self.toolbar.removeItem(at: index)
        }
        
        self.toolbarItems = items
        self.itemIdentifiers = identifiers
        
        // Set new items
        for (index, identifier) in identifiers.enumerated() {
            self.toolbar.insertItem(withItemIdentifier: identifier, at: index)
        }
    }
    
    //
    // MARK: - Toolbar delegate
    //
    
    func toolbarDefaultItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        return self.itemIdentifiers ?? []
    }
    
    func toolbarAllowedItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        return self.itemIdentifiers ?? []
    }
    
    func toolbar(_ toolbar: NSToolbar, itemForItemIdentifier itemIdentifier: NSToolbarItem.Identifier, willBeInsertedIntoToolbar flag: Bool) -> NSToolbarItem? {
        return self.toolbarItems?.first(where: { $0.itemIdentifier == itemIdentifier })
    }
    
}
