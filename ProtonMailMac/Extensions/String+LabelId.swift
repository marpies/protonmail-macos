//
//  String+LabelId.swift
//  ProtonMailMac
//
//  Created by Marcel Piešťanský on 14.10.2021.
//  Copyright © 2021 marpies. All rights reserved.
//

import Foundation

extension String {
    
    func isLabel(_ label: MailboxSidebar.Item) -> Bool {
        return self == label.id
    }
    
}
