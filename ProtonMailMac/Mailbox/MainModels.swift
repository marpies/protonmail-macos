//
//  MainModels.swift
//  ProtonMailMac
//
//  Created by Marcel Piešťanský on 25.08.2021.
//  Copyright (c) 2021 marpies. All rights reserved.
//

import Foundation
import AppKit

extension NSToolbarItem.Identifier {
    static let trackingItem1: NSToolbarItem.Identifier = NSToolbarItem.Identifier(rawValue: "TrackingItem1")
    static let trackingItem2: NSToolbarItem.Identifier = NSToolbarItem.Identifier(rawValue: "TrackingItem2")
    static let refreshMailbox: NSToolbarItem.Identifier = NSToolbarItem.Identifier(rawValue: "RefreshMailbox")
    static let moveToGroup: NSToolbarItem.Identifier = NSToolbarItem.Identifier(rawValue: "MoveToGroup")
    static let moveToTrash: NSToolbarItem.Identifier = NSToolbarItem.Identifier(rawValue: "MoveToTrash")
    static let moveToArchive: NSToolbarItem.Identifier = NSToolbarItem.Identifier(rawValue: "MoveToArchive")
    static let moveToSpam: NSToolbarItem.Identifier = NSToolbarItem.Identifier(rawValue: "MoveToSpam")
    static let setLabels: NSToolbarItem.Identifier = NSToolbarItem.Identifier(rawValue: "SetLabels")
    static let moveToFolder: NSToolbarItem.Identifier = NSToolbarItem.Identifier(rawValue: "MoveToFolder")
    static let replyForwardGroup: NSToolbarItem.Identifier = NSToolbarItem.Identifier(rawValue: "ReplyForwardGroup")
    static let replyToSender: NSToolbarItem.Identifier = NSToolbarItem.Identifier(rawValue: "ReplyToSender")
    static let replyToAll: NSToolbarItem.Identifier = NSToolbarItem.Identifier(rawValue: "ReplyToAll")
    static let forwardMessage: NSToolbarItem.Identifier = NSToolbarItem.Identifier(rawValue: "ForwardMessage")
}

enum Main {
    
    enum Notifications {
        struct ConversationCountsUpdate: NotificationType {
            static var name: Notification.Name {
                return Notification.Name("Main.ConversationCountsUpdate")
            }
            
            var name: Notification.Name {
                return ConversationCountsUpdate.name
            }
            
            var userInfo: [AnyHashable : Any]? {
                return ["unread": self.unread, "total": self.total, "userId": self.userId]
            }
            
            /// Item id to number of conversations.
            let unread: [String: Int]
            
            /// Item id to number of conversations.
            let total: [String: Int]
            let userId: String

            init(unread: [String: Int], total: [String: Int], userId: String) {
                self.unread = unread
                self.total = total
                self.userId = userId
            }
            
            init?(notification: Notification?) {
                guard let name = notification?.name,
                      name == ConversationCountsUpdate.name,
                      let userId = notification?.userInfo?["userId"] as? String,
                      let total = notification?.userInfo?["total"] as? [String: Int],
                      let unread = notification?.userInfo?["unread"] as? [String: Int] else { return nil }
                
                self.unread = unread
                self.total = total
                self.userId = userId
            }
        }
        
        struct ToolbarAction: NotificationType {
            static var name: Notification.Name {
                return Notification.Name("Main.toolbarAction")
            }
            
            var name: Notification.Name {
                return ToolbarAction.name
            }
            
            var userInfo: [AnyHashable : Any]? {
                return ["itemId": self.itemId]
            }
            
            let itemId: NSToolbarItem.Identifier

            init(itemId: NSToolbarItem.Identifier) {
                self.itemId = itemId
            }
            
            init?(notification: Notification?) {
                guard let name = notification?.name,
                      name == ToolbarAction.name,
                      let itemId = notification?.userInfo?["itemId"] as? NSToolbarItem.Identifier else { return nil }
                
                self.itemId = itemId
            }
        }
        
        struct ToolbarMenuItemAction: NotificationType {
            static var name: Notification.Name {
                return Notification.Name("Main.toolbarMenuItemAction")
            }
            
            var name: Notification.Name {
                return ToolbarMenuItemAction.name
            }
            
            var userInfo: [AnyHashable : Any]? {
                return ["action": self.action]
            }
            
            let action: Main.ToolbarItem.Menu.Item.Action

            init(action: Main.ToolbarItem.Menu.Item.Action) {
                self.action = action
            }
            
            init?(notification: Notification?) {
                guard let name = notification?.name,
                      name == ToolbarMenuItemAction.name,
                      let action = notification?.userInfo?["action"] as? Main.ToolbarItem.Menu.Item.Action else { return nil }
                
                self.action = action
            }
        }
    }
    
    enum ToolbarItem {
        enum Menu {
            enum Item {
                enum StateValue {
                    case off, on, mixed
                }
                
                enum Action {
                    case moveToFolder(folderId: String)
                    case updateLabel(labelId: String, apply: Bool)
                }
                
                case separator
                case item(model: MailboxSidebar.Item.Response, state: Main.ToolbarItem.Menu.Item.StateValue?)
            }
        }
        
        enum ViewModel {
            case spacer
            case trackingItem(id: NSToolbarItem.Identifier, index: Int)
            case button(id: NSToolbarItem.Identifier, label: String, tooltip: String, icon: String, isEnabled: Bool)
            case group(id: NSToolbarItem.Identifier, items: [Main.ToolbarItem.ViewModel])
            case buttonMenu(id: NSToolbarItem.Identifier, title: String, label: String, tooltip: String, icon: String, isEnabled: Bool, items: [MenuItem])
            case imageMenu(id: NSToolbarItem.Identifier, label: String, tooltip: String, icon: String, isEnabled: Bool, items: [MenuItem])
        }
    }

	//
	// MARK: - Init
	//

	enum Init {
		struct Request {
		}

		struct Response {
		}

		struct ViewModel {
            let loadingMessage: String
		}
	}
    
    //
    // MARK: - Load title
    //
    
    enum LoadTitle {
        struct Request {
            let labelId: String
        }
        
        struct Response {
            let item: MailboxSidebar.Item
            let numItems: Int
        }
        
        struct ViewModel {
            let title: String
            let subtitle: String?
        }
    }
    
    //
    // MARK: - Mailbox selection did update
    //
    
    enum MailboxSelectionDidUpdate {
        struct Request {
            let type: Mailbox.SelectionType
        }
    }
    
    //
    // MARK: - Update toolbar
    //
    
    enum UpdateToolbar {
        class Response {
            let isSelectionActive: Bool
            let isMultiSelection: Bool
            let labelItems: [Main.ToolbarItem.Menu.Item]?
            let folderItems: [Main.ToolbarItem.Menu.Item]?

            init(isSelectionActive: Bool, isMultiSelection: Bool, labelItems: [Main.ToolbarItem.Menu.Item]?, folderItems: [Main.ToolbarItem.Menu.Item]?) {
                self.isSelectionActive = isSelectionActive
                self.isMultiSelection = isMultiSelection
                self.labelItems = labelItems
                self.folderItems = folderItems
            }
        }
        
        class ViewModel {
            let identifiers: [NSToolbarItem.Identifier]
            let items: [Main.ToolbarItem.ViewModel]

            init(identifiers: [NSToolbarItem.Identifier], items: [Main.ToolbarItem.ViewModel]) {
                self.identifiers = identifiers
                self.items = items
            }
        }
    }
    
    //
    // MARK: - Toolbar action
    //
    
    enum ToolbarAction {
        struct Request {
            let id: NSToolbarItem.Identifier
        }
    }
    
    //
    // MARK: - Toolbar menu item tap
    //
    
    enum ToolbarMenuItemTap {
        struct Request {
            let id: MenuItemIdentifier
            let state: NSControl.StateValue
        }
    }
    
}
