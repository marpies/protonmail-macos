//
//  NSControl+Extensions.swift
//  ProtonMailMac
//
//  Created by Marcel Piešťanský on 27.08.2021.
//  Copyright © 2021 marpies. All rights reserved.
//

import Foundation
import AppKit

extension NSControl {
    
    func setLargeControlSize() {
        if #available(macOS 11.0, *) {
            self.controlSize = .large
        }
    }
    
}
