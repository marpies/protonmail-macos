//
//  AppearanceAdaptingView.swift
//  ProtonMailMac
//
//  Created by Marcel Piešťanský on 16.10.2021.
//  Copyright © 2021 marpies. All rights reserved.
//

import Cocoa

/// View that update its layer's background color when appearance settings changes (light/dark mode).
class AppearanceAdaptingView: NSView {

    /// Background color for the layer.
    var backgroundColor: NSColor? {
        didSet {
            self.wantsLayer = self.backgroundColor != nil
            
            self.layer?.backgroundColor = self.backgroundColor?.cgColor
        }
    }
    
    override func updateLayer() {
        super.updateLayer()
        
        self.layer?.backgroundColor = self.backgroundColor?.cgColor
    }
    
}
