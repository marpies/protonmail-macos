//
//  NSColor+Hex.swift
//  ProtonMailMac
//
//  Created by Marcel Piešťanský on 05.09.2021.
//  Copyright © 2021 marpies. All rights reserved.
//

import Foundation
import AppKit

extension NSColor {
    
    convenience init(hexColorCode: String) {
        var red:   CGFloat = 0.0
        var green: CGFloat = 0.0
        var blue:  CGFloat = 0.0
        var alpha: CGFloat = 1.0
        
        if hexColorCode.hasPrefix("#") {
            let index   = hexColorCode.index(hexColorCode.startIndex, offsetBy: 1)
            let hex     = String(hexColorCode[index...])
            let scanner = Scanner(string: hex)
            var hexValue: CUnsignedLongLong = 0
            
            if scanner.scanHexInt64(&hexValue) {
                if hex.count == 6 {
                    red   = CGFloat((hexValue & 0xFF0000) >> 16) / 255.0
                    green = CGFloat((hexValue & 0x00FF00) >> 8)  / 255.0
                    blue  = CGFloat(hexValue & 0x0000FF) / 255.0
                } else if hex.count == 8 {
                    red   = CGFloat((hexValue & 0xFF000000) >> 24) / 255.0
                    green = CGFloat((hexValue & 0x00FF0000) >> 16) / 255.0
                    blue  = CGFloat((hexValue & 0x0000FF00) >> 8)  / 255.0
                    alpha = CGFloat(hexValue & 0x000000FF)         / 255.0
                } else {
                    PMLog.D("invalid hex code string, length should be 7 or 9")
                }
            } else {
                PMLog.D("scan hex error")
            }
        } else {
            PMLog.D("invalid hex code string, missing '#' as prefix")
        }
        
        self.init(red:red, green:green, blue:blue, alpha:alpha)
    }
    
}
