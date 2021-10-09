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
    
    private lazy var toolbarDelegate = AppToolbarDelegate(toolbar: self.toolbar)
    
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
        
        if #available(macOS 11.0, *) {
            self.window?.toolbarStyle = .unified
        }
    }
    
}
