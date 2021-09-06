//
//  MailboxSidebarRowView.swift
//  ProtonMailMac
//
//  Created by Marcel Piešťanský on 27.08.2021.
//  Copyright © 2021 marpies. All rights reserved.
//

import Cocoa

class MailboxSidebarRowView: NSTableRowView {
    
    override var isEmphasized: Bool {
        get {
            return false
        }
        set {
            // Ignore, we want it to be false at all times
        }
    }
    
}
