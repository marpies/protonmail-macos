//
//  NSImage+Tint.swift
//  ProtonMailMac
//
//  Created by Marcel Piešťanský on 22.10.2021.
//  Copyright © 2021 marpies. All rights reserved.
//

import Foundation
import AppKit

extension NSImage {
    
    /// Creates a new image tinted to the given color.
    /// - Parameter color: The color of the tint.
    /// - Returns: The new image tinted to the given color, or the source image if the `color` is `nil`.
    func tinted(color: NSColor?) -> NSImage {
        guard let color = color else { return self }
        
        return NSImage(size: self.size, flipped: false) { rect in
            self.draw(in: rect)
            color.set()
            rect.fill(using: .sourceAtop)
            return true
        }
    }
    
}
