//
//  MainWindowController.swift
//  ProtonMailMac
//
//  Created by Marcel Piešťanský on 24.08.2021.
//  Copyright © 2021 marpies. All rights reserved.
//

import Foundation
import AppKit
import Swinject

class MainWindowController: NSWindowController {
    
    private var resolver: Resolver?
    
    private let toolbar = NSToolbar(identifier: "main")
    
    private lazy var toolbarDelegate = ToolbarDelegate(toolbar: self.toolbar)
    
    convenience init(resolver: Resolver) {
        self.init(windowNibName: "")
        
        self.resolver = resolver
    }
    
    override func loadWindow() {
        let windowSize: NSSize = NSSize.defaultWindow
        let screenSize = NSScreen.main?.frame.size ?? .zero
        let rect: NSRect = NSRect(x: (screenSize.width - windowSize.width) / 2, y: (screenSize.height - windowSize.height) / 2, width: windowSize.width, height: windowSize.height)
        
        let mainVC: AppViewController = self.resolver!.resolve(AppViewController.self)!
        mainVC.toolbarDelegate = self.toolbarDelegate
        
        self.window = MainWindow(contentRect: rect, styleMask: [], backing: .buffered, defer: true, screen: NSScreen.main)
        self.window?.titlebarAppearsTransparent = true
        self.window?.styleMask.insert(.fullSizeContentView)
        self.window?.contentViewController = mainVC
        
        self.toolbar.displayMode = .iconOnly
        
        self.window?.toolbar = self.toolbar
        self.window?.toolbarStyle = .unified
    }
    
}


class ToolbarDelegate: NSObject, NSToolbarDelegate, ToolbarUtilizingDelegate {
    
    private var toolbarItems: [NSToolbarItem]?
    private var itemIdentifiers: [NSToolbarItem.Identifier]?
    
    let toolbar: NSToolbar
    
    init(toolbar: NSToolbar) {
        self.toolbar = toolbar
        
        super.init()
        
        self.toolbar.delegate = self
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
