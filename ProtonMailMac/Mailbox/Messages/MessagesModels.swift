//
//  MessagesModels.swift
//  ProtonMailMac
//
//  Created by Marcel Piešťanský on 05.09.2021.
//  Copyright (c) 2021 marpies. All rights reserved.
//

import Foundation
import AppKit

extension Notification.Name {
    static let MessagesLoadDidTimeout: Notification.Name = Notification.Name(rawValue: "Messages.loadDidTimeout")
    static let MessagesServerUnreachable: Notification.Name = Notification.Name(rawValue: "Messages.serverUnreachable")
}

enum Messages {
    
    enum Notifications {
        struct MessageUpdate: NotificationType {
            static var name: Notification.Name {
                return Notification.Name("Messages.messageUpdate")
            }
            
            var name: Notification.Name {
                return MessageUpdate.name
            }
            
            var userInfo: [AnyHashable : Any]? {
                return ["messageId": self.messageId]
            }
            
            let messageId: String
            
            init(messageId: String) {
                self.messageId = messageId
            }
            
            init?(notification: Notification?) {
                guard let name = notification?.name,
                      name == MessageUpdate.name,
                      let messageId = notification?.userInfo?["messageId"] as? String else { return nil }
                
                self.messageId = messageId
            }
        }
        
        struct MessagesUpdate: NotificationType {
            static var name: Notification.Name {
                return Notification.Name("Messages.messagesUpdate")
            }
            
            var name: Notification.Name {
                return MessagesUpdate.name
            }
            
            var userInfo: [AnyHashable : Any]? {
                return ["messageIds": self.messageIds]
            }
            
            let messageIds: Set<String>
            
            init(messageIds: Set<String>) {
                self.messageIds = messageIds
            }
            
            init?(notification: Notification?) {
                guard let name = notification?.name,
                      name == MessagesUpdate.name,
                      let messageIds = notification?.userInfo?["messageIds"] as? Set<String> else { return nil }
                
                self.messageIds = messageIds
            }
        }
    }
    
    enum MessageTime {
        case today(Date)
        case yesterday(Date)
        case other(Date)
        
        var date: Date {
            switch self {
            case .today(let date):
                return date
            case .yesterday(let date):
                return date
            case .other(let date):
                return date
            }
        }
    }
    
    enum Icon {
        class ViewModel {
            let icon: String
            let color: NSColor
            let tooltip: String

            init(icon: String, color: NSColor, tooltip: String) {
                self.icon = icon
                self.color = color
                self.tooltip = tooltip
            }
        }
    }
    
    enum Folder {
        case draft
        case inbox
        case outbox
        case spam
        case archive
        case trash
        case custom(id: String, title: String)
        
        var id: String {
            switch self {
            case .draft:
                return "1"
            case .inbox:
                return "0"
            case .outbox:
                return "2"
            case .spam:
                return "4"
            case .archive:
                return "6"
            case .trash:
                return "3"
            case .custom(let id, _):
                return id
            }
        }
        
        init(id: String, title: String?) {
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
            case "6":
                self = .archive
            default:
                self = .custom(id: id, title: title ?? "")
            }
        }
        
        class Response {
            let kind: Messages.Folder
            let color: NSColor?
            
            init(kind: Messages.Folder, color: NSColor?) {
                self.kind = kind
                self.color = color
            }
        }
        
        class ViewModel {
            let id: String
            let title: String
            let icon: String
            let color: NSColor?

            init(id: String, title: String, icon: String, color: NSColor?) {
                self.id = id
                self.title = title
                self.icon = icon
                self.color = color
            }
        }
    }
    
    enum Label {
        class Response {
            let id: String
            let title: String
            let color: NSColor

            init(id: String, title: String, color: NSColor) {
                self.id = id
                self.title = title
                self.color = color
            }
        }
        
        class ViewModel {
            let id: String
            let title: String
            let color: NSColor
            
            init(id: String, title: String, color: NSColor) {
                self.id = id
                self.title = title
                self.color = color
            }
        }
    }
    
    enum Attachment {
        struct ViewModel {
            let icon: String
            let title: String
        }
    }
    
    enum Star {
        class ViewModel {
            let icon: String
            let isSelected: Bool
            let color: NSColor
            let tooltip: String

            init(icon: String, isSelected: Bool, color: NSColor, tooltip: String) {
                self.icon = icon
                self.isSelected = isSelected
                self.color = color
                self.tooltip = tooltip
            }
        }
    }
    
    enum Message {
        enum Metadata {
            struct Response {
                let isEndToEndEncrypted: Bool
                let isInternal: Bool
                let isExternal: Bool
                let isPgpInline: Bool
                let isPgpMime: Bool
                let isSignedMime: Bool
                let isPlainText: Bool
                let isMultipartMixed: Bool
            }
        }
        
        enum RemoteContentBox {
            class ViewModel {
                let message: String
                let button: String
                
                init(message: String, button: String) {
                    self.message = message
                    self.button = button
                }
            }
        }
        
        enum Header {
            class ViewModel {
                let title: String
                let labels: [Messages.Label.ViewModel]?
                let folders: [Messages.Folder.ViewModel]
                let date: String
                let starIcon: Messages.Star.ViewModel
                let isRead: Bool
                let draftLabel: Messages.Label.ViewModel?
                let repliedIcon: Messages.Icon.ViewModel?
                let attachmentIcon: Messages.Attachment.ViewModel?

                init(title: String, labels: [Messages.Label.ViewModel]?, folders: [Messages.Folder.ViewModel], date: String, starIcon: Messages.Star.ViewModel, isRead: Bool, draftLabel: Messages.Label.ViewModel?, repliedIcon: Messages.Icon.ViewModel?, attachmentIcon: Messages.Attachment.ViewModel?) {
                    self.title = title
                    self.labels = labels
                    self.folders = folders
                    self.date = date
                    self.starIcon = starIcon
                    self.isRead = isRead
                    self.draftLabel = draftLabel
                    self.repliedIcon = repliedIcon
                    self.attachmentIcon = attachmentIcon
                }
            }
        }
        
        enum Contents {
            class Response {
                let contents: WebContents
                let loader: WebContentsSecureLoader

                init(contents: WebContents, loader: WebContentsSecureLoader) {
                    self.contents = contents
                    self.loader = loader
                }
            }
            
            class ViewModel {
                let contents: WebContents
                let loader: WebContentsSecureLoader
                
                init(contents: WebContents, loader: WebContentsSecureLoader) {
                    self.contents = contents
                    self.loader = loader
                }
            }
        }
        
        class Response: Hashable {
            let id: String
            let subject: String
            let senderName: String
            let time: Messages.MessageTime
            let isStarred: Bool
            let isRepliedTo: Bool
            let numAttachments: Int
            let hasInlineAttachments: Bool
            let isRead: Bool
            let isDraft: Bool
            let metadata: Messages.Message.Metadata.Response
            let folders: [Messages.Folder.Response]?
            let labels: [Messages.Label.Response]?
            var hasRemoteContent: Bool?
            var body: String?
            var isExpanded: Bool
            var contents: Messages.Message.Contents.Response?
            
            init(id: String, subject: String, senderName: String, time: Messages.MessageTime, isStarred: Bool, isRepliedTo: Bool, numAttachments: Int, hasInlineAttachments: Bool, isRead: Bool, isDraft: Bool, metadata: Messages.Message.Metadata.Response, folders: [Messages.Folder.Response]?, labels: [Messages.Label.Response]?, body: String?, isExpanded: Bool) {
                self.id = id
                self.subject = subject
                self.senderName = senderName
                self.time = time
                self.isStarred = isStarred
                self.isRepliedTo = isRepliedTo
                self.numAttachments = numAttachments
                self.hasInlineAttachments = hasInlineAttachments
                self.isRead = isRead
                self.isDraft = isDraft
                self.metadata = metadata
                self.folders = folders
                self.labels = labels
                self.body = body
                self.isExpanded = isExpanded
            }
            
            func hash(into hasher: inout Hasher) {
                hasher.combine(self.id)
                hasher.combine(self.subject)
                hasher.combine(self.senderName)
                hasher.combine(self.time.date.timeIntervalSince1970)
                hasher.combine(self.numAttachments)
                hasher.combine(self.isRead)
                hasher.combine(self.isStarred)
                
                self.folders?.forEach { hasher.combine($0.kind.id) }
                self.labels?.forEach { hasher.combine($0.id) }
            }
            
            static func == (lhs: Messages.Message.Response, rhs: Messages.Message.Response) -> Bool {
                return lhs.hashValue == rhs.hashValue
            }
        }
        
        class ViewModel {
            let id: String
            let header: Messages.Message.Header.ViewModel

            init(id: String, header: Messages.Message.Header.ViewModel) {
                self.id = id
                self.header = header
            }
        }
    }

	//
	// MARK: - Load messages
	//

	enum LoadMessages {
		struct Request {
            let labelId: String
		}

		class Response {
            let messages: [Messages.Message.Response]
            let isServerResponse: Bool

            init(messages: [Messages.Message.Response], isServerResponse: Bool) {
                self.messages = messages
                self.isServerResponse = isServerResponse
            }
		}

		class ViewModel {
            let messages: [Messages.Message.ViewModel]
            let removeErrorView: Bool

            init(messages: [Messages.Message.ViewModel], removeErrorView: Bool) {
                self.messages = messages
                self.removeErrorView = removeErrorView
            }
		}
	}
    
    //
    // MARK: - Update messages
    //
    
    enum UpdateMessages {
        class Response {
            let messages: [Messages.Message.Response]
            let removeSet: IndexSet?
            let insertSet: IndexSet?
            let updateSet: IndexSet?

            init(messages: [Messages.Message.Response], removeSet: IndexSet?, insertSet: IndexSet?, updateSet: IndexSet?) {
                self.messages = messages
                self.removeSet = removeSet
                self.insertSet = insertSet
                self.updateSet = updateSet
            }
        }
        
        class ViewModel {
            let messages: [Messages.Message.ViewModel]
            let removeSet: IndexSet?
            let insertSet: IndexSet?
            let updateSet: IndexSet?
            
            init(messages: [Messages.Message.ViewModel], removeSet: IndexSet?, insertSet: IndexSet?, updateSet: IndexSet?) {
                self.messages = messages
                self.removeSet = removeSet
                self.insertSet = insertSet
                self.updateSet = updateSet
            }
        }
    }
    
    //
    // MARK: - Update message
    //
    
    enum UpdateMessage {
        class Response {
            let message: Messages.Message.Response
            let index: Int

            init(message: Messages.Message.Response, index: Int) {
                self.message = message
                self.index = index
            }
        }
        
        class ViewModel {
            let message: Messages.Message.ViewModel
            let index: Int
            
            init(message: Messages.Message.ViewModel, index: Int) {
                self.message = message
                self.index = index
            }
        }
    }
    
    //
    // MARK: - Load error
    //
    
    enum LoadError {
        struct Response {
            let error: NSError
        }
        
        struct ViewModel {
            let message: String
            let button: String
        }
    }
    
    //
    // MARK: - Star message
    //
    
    enum StarMessage {
        struct Request {
            let id: String
        }
    }
    
    //
    // MARK: - Unstar message
    //
    
    enum UnstarMessage {
        struct Request {
            let id: String
        }
    }
    
}
