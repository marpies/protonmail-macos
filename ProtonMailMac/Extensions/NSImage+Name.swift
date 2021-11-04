//
//  NSImage+Name.swift
//  ProtonMailMac
//
//  Created by Marcel Piešťanský on 02.11.2021.
//  Copyright © 2021 marpies. All rights reserved.
//

import Foundation
import AppKit

extension NSImage {
    
    static func universal(name: String) -> NSImage? {
        if #available(macOS 11.0, *) {
            return NSImage(systemSymbolName: name, accessibilityDescription: nil)
        }
        return NSImage(named: NSImage.Name(name))
    }
    
}
