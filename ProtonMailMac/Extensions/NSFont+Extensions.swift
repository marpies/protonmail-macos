//
//  NSFont+Extensions.swift
//  ProtonMailMac
//
//  Created by Marcel Piešťanský on 27.08.2021.
//  Copyright © 2021 marpies. All rights reserved.
//

import Foundation
import AppKit

extension NSFont {
    
    /// Enum matching macOS 11.0+ NSFont.TextStyle.
    enum LegacyTextStyle {
        case body
        case callout
        case caption1
        case caption2
        case footnote
        case headline
        case subheadline
        case largeTitle
        case title1
        case title2
        case title3
        
        var fontSize: CGFloat {
            switch self {
            case .body:
                return 13
            case .callout:
                return 12
            case .caption1, .caption2, .footnote:
                return 10
            case .headline:
                return 13
            case .subheadline:
                return 11
            case .largeTitle:
                return 26
            case .title1:
                return 22
            case .title2:
                return 17
            case .title3:
                return 15
            }
        }
        
        var fontWeight: NSFont.Weight {
            switch self {
            case .headline:
                return .bold
            default:
                return .regular
            }
        }
    }
    
}

@available(macOS 11.0, *)
extension NSFont.LegacyTextStyle {
    
    var textStyle: NSFont.TextStyle {
        switch self {
        case .body:
            return .body
        case .callout:
            return .callout
        case .caption1:
            return .caption1
        case .caption2:
            return .caption2
        case .footnote:
            return .footnote
        case .headline:
            return .headline
        case .subheadline:
            return .subheadline
        case .largeTitle:
            return .largeTitle
        case .title1:
            return .title1
        case .title2:
            return .title2
        case .title3:
            return .title3
        }
    }
    
}
