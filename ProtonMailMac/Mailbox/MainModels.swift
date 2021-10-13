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
    }
    
    enum ToolbarItem {
        enum ViewModel {
            case spacer
            case trackingItem(id: NSToolbarItem.Identifier, index: Int)
            case button(id: NSToolbarItem.Identifier, label: String, tooltip: String, icon: String, isEnabled: Bool)
            case group(id: NSToolbarItem.Identifier, items: [Main.ToolbarItem.ViewModel])
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
            let isMultiSelection: Bool
            let type: Mailbox.TableItem.Kind
        }
    }
    
    //
    // MARK: - Update toolbar
    //
    
    enum UpdateToolbar {
        struct Response {
            let isSelectionActive: Bool
            let isMultiSelection: Bool
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
    
}
