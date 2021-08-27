//
//  NSView+Extensions.swift
//  ProtonMailMac
//
//  Created by Marcel Piešťanský on 27.08.2021.
//  Copyright © 2021 marpies. All rights reserved.
//

import Foundation
import AppKit
import SnapKit

extension NSView {
    
    var safeArea: ConstraintBasicAttributesDSL {
        if #available(macOS 11.0, *) {
            return self.safeAreaLayoutGuide.snp
        }
        return self.snp
    }
    
}
