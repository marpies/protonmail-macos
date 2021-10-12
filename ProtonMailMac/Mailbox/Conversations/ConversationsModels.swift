//
//  ConversationsModels.swift
//  ProtonMailMac
//
//  Created by Marcel Piešťanský on 16.09.2021.
//  Copyright (c) 2021 marpies. All rights reserved.
//

import Foundation

extension Notification.Name {
    static let ConversationsLoadDidTimeout: Notification.Name = Notification.Name(rawValue: "Conversations.loadDidTimeout")
    static let ConversationsServerUnreachable: Notification.Name = Notification.Name(rawValue: "Conversations.serverUnreachable")
}

enum Conversations {
    
    enum Notifications {
        struct ConversationUpdate: NotificationType {
            static var name: Notification.Name {
                return Notification.Name("Conversations.conversationUpdate")
            }
            
            var name: Notification.Name {
                return ConversationUpdate.name
            }
            
            var userInfo: [AnyHashable : Any]? {
                return ["conversationId": self.conversationId]
            }
            
            let conversationId: String

            init(conversationId: String) {
                self.conversationId = conversationId
            }
            
            init?(notification: Notification?) {
                guard let name = notification?.name,
                      name == ConversationUpdate.name,
                      let conversationId = notification?.userInfo?["conversationId"] as? String else { return nil }
                
                self.conversationId = conversationId
            }
        }
        
        struct ConversationsUpdate: NotificationType {
            static var name: Notification.Name {
                return Notification.Name("Conversations.conversationsUpdate")
            }
            
            var name: Notification.Name {
                return ConversationsUpdate.name
            }
            
            var userInfo: [AnyHashable : Any]? {
                return ["conversationIds": self.conversationIds]
            }
            
            let conversationIds: Set<String>
            
            init(conversationIds: Set<String>) {
                self.conversationIds = conversationIds
            }
            
            init?(notification: Notification?) {
                guard let name = notification?.name,
                      name == ConversationsUpdate.name,
                      let conversationIds = notification?.userInfo?["conversationIds"] as? Set<String> else { return nil }
                
                self.conversationIds = conversationIds
            }
        }
    }
    
    enum Conversation {
        class Response: Hashable {
            let id: String
            let subject: String
            let senderNames: [String]
            let time: Messages.MessageTime
            let numMessages: Int
            let numAttachments: Int
            let isRead: Bool
            let isStarred: Bool
            let folders: [Messages.Folder.Response]?
            let labels: [Messages.Label.Response]?

            init(id: String, subject: String, senderNames: [String], time: Messages.MessageTime, numMessages: Int, numAttachments: Int, isRead: Bool, isStarred: Bool, folders: [Messages.Folder.Response]?, labels: [Messages.Label.Response]?) {
                self.id = id
                self.subject = subject
                self.senderNames = senderNames
                self.time = time
                self.numMessages = numMessages
                self.numAttachments = numAttachments
                self.isRead = isRead
                self.isStarred = isStarred
                self.folders = folders
                self.labels = labels
            }
            
            func hash(into hasher: inout Hasher) {
                hasher.combine(self.id)
                hasher.combine(self.subject)
                hasher.combine(self.senderNames)
                hasher.combine(self.time.date.timeIntervalSince1970)
                hasher.combine(self.numMessages)
                hasher.combine(self.numAttachments)
                hasher.combine(self.isRead)
                hasher.combine(self.isStarred)
                
                self.folders?.forEach { hasher.combine($0.kind.id) }
                self.labels?.forEach { hasher.combine($0.id) }
            }
            
            static func == (lhs: Conversations.Conversation.Response, rhs: Conversations.Conversation.Response) -> Bool {
                return lhs.hashValue == rhs.hashValue
            }
        }
    }
    
    enum TableItem {
        enum Kind {
            case conversation, message
        }
        
        class ViewModel {
            let type: Conversations.TableItem.Kind
            let id: String
            let title: String
            let subtitle: String
            let time: String
            let isRead: Bool
            let starIcon: Messages.Star.ViewModel
            let folders: [Messages.Folder.ViewModel]?
            let labels: [Messages.Label.ViewModel]?
            let attachmentIcon: Messages.Attachment.ViewModel?

            init(type: Conversations.TableItem.Kind, id: String, title: String, subtitle: String, time: String, isRead: Bool, starIcon: Messages.Star.ViewModel, folders: [Messages.Folder.ViewModel]?, labels: [Messages.Label.ViewModel]?, attachmentIcon: Messages.Attachment.ViewModel?) {
                self.type = type
                self.id = id
                self.title = title
                self.subtitle = subtitle
                self.time = time
                self.isRead = isRead
                self.starIcon = starIcon
                self.folders = folders
                self.labels = labels
                self.attachmentIcon = attachmentIcon
            }
        }
    }
    
    //
    // MARK: - Load conversations
    //
    
    enum LoadConversations {
        class Response {
            let conversations: [Conversations.Conversation.Response]
            let isServerResponse: Bool
            
            init(conversations: [Conversations.Conversation.Response], isServerResponse: Bool) {
                self.conversations = conversations
                self.isServerResponse = isServerResponse
            }
        }
    }
    
    //
    // MARK: - Load messages
    //
    
    enum LoadMessages {
        class Response {
            let messages: [Messages.Message.Response]
            let isServerResponse: Bool
            
            init(messages: [Messages.Message.Response], isServerResponse: Bool) {
                self.messages = messages
                self.isServerResponse = isServerResponse
            }
        }
    }
    
    //
    // MARK: - Load items
    //
    
    enum LoadItems {
        struct Request {
            let labelId: String
        }
        
        class ViewModel {
            let items: [Conversations.TableItem.ViewModel]
            let removeErrorView: Bool
            
            init(items: [Conversations.TableItem.ViewModel], removeErrorView: Bool) {
                self.items = items
                self.removeErrorView = removeErrorView
            }
        }
    }
    
    //
    // MARK: - Update conversations
    //
    
    enum UpdateConversations {
        class Response {
            let conversations: [Conversations.Conversation.Response]
            let removeSet: IndexSet?
            let insertSet: IndexSet?
            let updateSet: IndexSet?
            
            init(conversations: [Conversations.Conversation.Response], removeSet: IndexSet?, insertSet: IndexSet?, updateSet: IndexSet?) {
                self.conversations = conversations
                self.removeSet = removeSet
                self.insertSet = insertSet
                self.updateSet = updateSet
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
    }
    
    //
    // MARK: - Update items
    //
    
    enum UpdateItems {
        class ViewModel {
            let items: [Conversations.TableItem.ViewModel]
            let removeSet: IndexSet?
            let insertSet: IndexSet?
            let updateSet: IndexSet?
            
            init(items: [Conversations.TableItem.ViewModel], removeSet: IndexSet?, insertSet: IndexSet?, updateSet: IndexSet?) {
                self.items = items
                self.removeSet = removeSet
                self.insertSet = insertSet
                self.updateSet = updateSet
            }
        }
    }
    
    //
    // MARK: - Update conversation
    //
    
    enum UpdateConversation {
        class Response {
            let conversation: Conversations.Conversation.Response
            let index: Int
            
            init(conversation: Conversations.Conversation.Response, index: Int) {
                self.conversation = conversation
                self.index = index
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
    }
    
    //
    // MARK: - Update item
    //
    
    enum UpdateItem {
        class ViewModel {
            let item: Conversations.TableItem.ViewModel
            let index: Int
            
            init(item: Conversations.TableItem.ViewModel, index: Int) {
                self.item = item
                self.index = index
            }
        }
    }
    
    //
    // MARK: - Update item star
    //
    
    enum UpdateItemStar {
        struct Request {
            let id: String
            let isOn: Bool
            let type: Conversations.TableItem.Kind
        }
    }
    
    //
    // MARK: - Items did select
    //
    
    enum ItemsDidSelect {
        struct Request {
            let ids: [String]
            let type: Conversations.TableItem.Kind
        }
    }
    
    //
    // MARK: - Load conversation
    //
    
    enum LoadConversation {
        struct Response {
            let id: String
        }
        
        struct ViewModel {
            let id: String
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
