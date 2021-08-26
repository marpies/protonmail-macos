//
//  AppWindow.swift
//  ProtonMailMac
//
//  Created by Marcel Piešťanský on 24.08.2021.
//

import Foundation
import AppKit

class MainWindow: NSWindow {
    
    override init(contentRect: NSRect, styleMask style: NSWindow.StyleMask, backing backingStoreType: NSWindow.BackingStoreType, defer flag: Bool) {
        super.init(contentRect: contentRect, styleMask: [.miniaturizable, .closable, .resizable, .titled],  backing: .buffered, defer: true)
        isMovableByWindowBackground = true
    }
    
}
