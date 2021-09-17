//
//  MessageStarPresenting.swift
//  ProtonMailMac
//
//  Created by Marcel Piešťanský on 17.09.2021.
//  Copyright © 2021 marpies. All rights reserved.
//

import Foundation
import AppKit

protocol MessageStarPresenting {
    func getStarIcon(isSelected: Bool) -> Messages.Star.ViewModel
}

extension MessageStarPresenting {
    
    func getStarIcon(isSelected: Bool) -> Messages.Star.ViewModel {
        let icon: String
        let tooltip: String
        
        if isSelected {
            icon = "star.fill"
            tooltip = NSLocalizedString("messageUnstarConversation", comment: "")
        } else {
            icon = "star"
            tooltip = NSLocalizedString("messageStarConversation", comment: "")
        }
        
        return Messages.Star.ViewModel(icon: icon, isSelected: isSelected, color: NSColor.systemOrange, tooltip: tooltip)
    }
    
}
