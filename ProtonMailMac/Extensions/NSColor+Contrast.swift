//
//  NSColor+Contrast.swift
//  ProtonMailMac
//
//  Created by Marcel Piešťanský on 10.09.2021.
//  Copyright © 2021 marpies. All rights reserved.
//

import Foundation
import AppKit

extension NSColor {
    
    var isLight: Bool {
        guard let comps = self.cgColor.components else { return false }
        
        let colorBrightness: CGFloat = ((comps[0] * 299) + (comps[1] * 587) + (comps[2] * 114)) / 1000;
        
        return colorBrightness >= 0.5
    }
    
}
