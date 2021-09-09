//
//  AppBadgeManaging.swift
//  ProtonMailMac
//
//  Created by Marcel Piešťanský on 09.09.2021.
//  Copyright © 2021 marpies. All rights reserved.
//

import Foundation
import AppKit

protocol AppBadgeManaging {
    func setAppBadge(_ value: Int)
}

extension AppBadgeManaging {
    
    func setAppBadge(_ value: Int) {
        DispatchQueue.main.async {
            NSApp.dockTile.badgeLabel = (value > 0) ? String(value) : nil
        }
    }
    
}
