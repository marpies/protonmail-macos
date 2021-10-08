//
//  LabelToSidebarItemParsing.swift
//  ProtonMailMac
//
//  Created by Marcel Piešťanský on 08.10.2021.
//  Copyright © 2021 marpies. All rights reserved.
//

import Foundation

protocol LabelToSidebarItemParsing {
    func getSidebarItemKind(response: Label) -> MailboxSidebar.Item
}

extension LabelToSidebarItemParsing {
    
    func getSidebarItemKind(response: Label) -> MailboxSidebar.Item {
        switch response.labelID {
        case "0":
            return .inbox
        case "1", "8":
            return .draft
        case "2", "7":
            return .outbox
        case "3":
            return .trash
        case "4":
            return .spam
        case "5":
            return .allMail
        case "6":
            return .archive
        case "10":
            return .starred
        default:
            return .custom(id: response.labelID, title: response.name, isFolder: response.exclusive)
        }
    }
    
}
