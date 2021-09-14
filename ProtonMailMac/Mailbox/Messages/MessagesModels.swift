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
    
    enum MessageTime {
        case today(Date)
        case yesterday(Date)
        case other(Date)
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
    
    enum Message {
        class Response {
            let id: String
            let subject: String
            let senderName: String
            let time: Messages.MessageTime
            let isStarred: Bool
            let numAttachments: Int
            let isRead: Bool
            let folders: [Messages.Folder.Response]?
            let labels: [Messages.Label.Response]?

            init(id: String, subject: String, senderName: String, time: Messages.MessageTime, isStarred: Bool, numAttachments: Int, isRead: Bool, folders: [Messages.Folder.Response]?, labels: [Messages.Label.Response]?) {
                self.id = id
                self.subject = subject
                self.senderName = senderName
                self.time = time
                self.isStarred = isStarred
                self.numAttachments = numAttachments
                self.isRead = isRead
                self.folders = folders
                self.labels = labels
            }
        }
        
        class ViewModel {
            let id: String
            let title: String
            let subtitle: String
            let time: String
            let isStarred: Bool
            let isRead: Bool
            let folders: [Messages.Folder.ViewModel]?
            let labels: [Messages.Label.ViewModel]?
            let attachmentIcon: Messages.Attachment.ViewModel?

            init(id: String, title: String, subtitle: String, time: String, isStarred: Bool, isRead: Bool, folders: [Messages.Folder.ViewModel]?, labels: [Messages.Label.ViewModel]?, attachmentIcon: Messages.Attachment.ViewModel?) {
                self.id = id
                self.title = title
                self.subtitle = subtitle
                self.time = time
                self.isStarred = isStarred
                self.isRead = isRead
                self.folders = folders
                self.labels = labels
                self.attachmentIcon = attachmentIcon
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
    
}
