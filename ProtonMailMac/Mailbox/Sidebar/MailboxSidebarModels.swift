//
//  MailboxSidebarModels.swift
//  ProtonMailMac
//
//  Created by Marcel Piešťanský on 27.08.2021.
//  Copyright (c) 2021 marpies. All rights reserved.
//

import Foundation
import AppKit

enum MailboxSidebar {
    
    enum Group {
        case inboxes, folders, labels
        
        struct Response {
            let kind: MailboxSidebar.Group
            let labels: [MailboxSidebar.Item.Response]
        }
        
        class ViewModel {
            let title: String
            let labels: [MailboxSidebar.Item.ViewModel]

            init(title: String, labels: [MailboxSidebar.Item.ViewModel]) {
                self.title = title
                self.labels = labels
            }
        }
    }
    
    enum Item {
        case draft
        case inbox
        case outbox
        case spam
        case archive
        case trash
        case allMail
        case starred
        case custom(id: String, title: String, isFolder: Bool)
        
        var id: String {
            switch self {
            case .draft:
                return "8"
            case .inbox:
                return "0"
            case .outbox:
                return "7"
            case .spam:
                return "4"
            case .archive:
                return "6"
            case .trash:
                return "3"
            case .allMail:
                return "5"
            case .starred:
                return "10"
            case .custom(let id, _, _):
                return id
            }
        }
        
        var hiddenId: String {
            switch self {
            case .draft:
                return "1"
            case .outbox:
                return "2"
            default:
                return self.id
            }
        }
        
        init(id: String, title: String?, isFolder: Bool = false) {
            switch id {
            case "0":
                self = .inbox
            case "1", "8":
                self = .draft
            case "2", "7":
                self = .outbox
            case "3":
                self = .trash
            case "4":
                self = .spam
            case "5":
                self = .allMail
            case "6":
                self = .archive
            case "10":
                self = .starred
            default:
                self = .custom(id: id, title: title ?? "", isFolder: isFolder)
            }
        }
        
        class Response {
            let kind: MailboxSidebar.Item
            let color: NSColor?
            var children: [MailboxSidebar.Item.Response]?

            init(kind: MailboxSidebar.Item, color: NSColor?) {
                self.kind = kind
                self.color = color
            }
            
            func addChild(_ item: MailboxSidebar.Item.Response) {
                if self.children == nil {
                    self.children = []
                }
                self.children?.append(item)
            }
        }
        
        class ViewModel {
            let id: String
            let title: String
            let icon: String
            let children: [MailboxSidebar.Item.ViewModel]?
            let color: NSColor?

            init(id: String, title: String, icon: String, children: [MailboxSidebar.Item.ViewModel]?, color: NSColor?) {
                self.id = id
                self.title = title
                self.icon = icon
                self.children = children
                self.color = color
            }
        }
    }

	//
	// MARK: - Init
	//

	enum Init {
		struct Request {
		}

		struct Response {
            let groups: [MailboxSidebar.Group.Response]
            let selectedRow: Int
		}

		struct ViewModel {
            let groups: [MailboxSidebar.Group.ViewModel]
            let selectedRow: Int
		}
	}
    
    //
    // MARK: - Refresh groups
    //
    
    enum RefreshGroups {
        struct Response {
            let groups: [MailboxSidebar.Group.Response]
            let selectedRow: Int
        }
        
        struct ViewModel {
            let groups: [MailboxSidebar.Group.ViewModel]
            let selectedRow: Int
        }
    }
    
    //
    // MARK: - Item selected
    //
    
    enum ItemSelected {
        struct Request {
            let id: String
        }
    }
    
}
