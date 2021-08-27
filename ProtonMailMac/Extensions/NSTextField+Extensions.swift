//
//  NSTextField+Extensions.swift
//  ProtonMailMac
//
//  Created by Marcel Piešťanský on 25.08.2021.
//  Copyright © 2021 marpies. All rights reserved.
//

import Foundation
import AppKit

extension NSTextField {
    
    static var asLabel: NSTextField {
        let label: NSTextField = NSTextField()
        label.isBezeled = false
        label.isSelectable = false
        label.isEditable = false
        label.isBordered = false
        label.drawsBackground = false
        return label
    }
    
    static var asInput: NSTextField {
        let label: NSTextField = NSTextField()
        label.isBezeled = false
        label.isSelectable = false
        label.isEditable = true
        label.isBordered = false
        return label
    }
    
    func setPreferredFont(style: NSFont.LegacyTextStyle) {
        if #available(macOS 11.0, *) {
            self.font = NSFont.preferredFont(forTextStyle: style.textStyle)
        } else {
            self.font = NSFont.systemFont(ofSize: style.fontSize, weight: style.fontWeight)
        }
    }
    
}
