//
//  ComposerWindowController.swift
//  ProtonMailMac
//
//  Created by Marcel Piešťanský on 26.11.2021.
//  Copyright © 2021 marpies. All rights reserved.
//

import Cocoa
import Swinject

class ComposerWindowController: NSWindowController {
    
    private var resolver: Resolver?
    private let toolbar: NSToolbar = NSToolbar(identifier: "composer")
    
    private lazy var toolbarDelegate: AppToolbarDelegate = AppToolbarDelegate(toolbar: self.toolbar)
    
    convenience init(resolver: Resolver) {
        self.init(windowNibName: "")
        
        self.resolver = resolver
    }
    
    override func loadWindow() {
        let windowSize: NSSize = NSSize(width: NSSize.defaultWindow.width / 2, height: NSSize.defaultWindow.height * 0.8)
        let screenSize = NSScreen.main?.frame.size ?? .zero
        let rect: NSRect = NSRect(x: (screenSize.width - windowSize.width) / 2, y: (screenSize.height - windowSize.height) / 2, width: windowSize.width, height: windowSize.height)
        
        let composerVC: ComposerViewController = self.resolver!.resolve(ComposerViewController.self)!
        composerVC.toolbarDelegate = self.toolbarDelegate
        
        self.window = MainWindow(contentRect: rect, styleMask: [], backing: .buffered, defer: true, screen: NSScreen.main)
        self.window?.styleMask.insert(.fullSizeContentView)
        self.window?.contentViewController = composerVC
        self.window?.titlebarAppearsTransparent = false
        
        self.toolbar.displayMode = .default
        self.toolbar.allowsUserCustomization = true
        
        self.window?.titleVisibility = .hidden
        self.window?.delegate = composerVC
        self.window?.toolbar = self.toolbar
        
        if #available(macOS 11.0, *) {
            self.window?.toolbarStyle = .automatic
        }
    }

}
