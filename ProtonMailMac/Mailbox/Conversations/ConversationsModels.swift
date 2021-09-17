//
//  ConversationsModels.swift
//  ProtonMailMac
//
//  Created by Marcel Piešťanský on 16.09.2021.
//  Copyright (c) 2021 marpies. All rights reserved.
//

import Foundation

enum Conversations {
    
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
        
        class ViewModel {
            let id: String
            let title: String
            let subtitle: String
            let time: String
            let isRead: Bool
            let starIcon: Messages.Star.ViewModel
            let folders: [Messages.Folder.ViewModel]?
            let labels: [Messages.Label.ViewModel]?
            let attachmentIcon: Messages.Attachment.ViewModel?
            
            init(id: String, title: String, subtitle: String, time: String, isRead: Bool, starIcon: Messages.Star.ViewModel, folders: [Messages.Folder.ViewModel]?, labels: [Messages.Label.ViewModel]?, attachmentIcon: Messages.Attachment.ViewModel?) {
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
        struct Request {
            let labelId: String
        }
        
        class Response {
            let conversations: [Conversations.Conversation.Response]
            let isServerResponse: Bool
            
            init(conversations: [Conversations.Conversation.Response], isServerResponse: Bool) {
                self.conversations = conversations
                self.isServerResponse = isServerResponse
            }
        }
        
        class ViewModel {
            let conversations: [Conversations.Conversation.ViewModel]
            let removeErrorView: Bool
            
            init(conversations: [Conversations.Conversation.ViewModel], removeErrorView: Bool) {
                self.conversations = conversations
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
        
        class ViewModel {
            let conversations: [Conversations.Conversation.ViewModel]
            let removeSet: IndexSet?
            let insertSet: IndexSet?
            let updateSet: IndexSet?
            
            init(conversations: [Conversations.Conversation.ViewModel], removeSet: IndexSet?, insertSet: IndexSet?, updateSet: IndexSet?) {
                self.conversations = conversations
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
        
        class ViewModel {
            let conversation: Conversations.Conversation.ViewModel
            let index: Int
            
            init(conversation: Conversations.Conversation.ViewModel, index: Int) {
                self.conversation = conversation
                self.index = index
            }
        }
    }
    
    //
    // MARK: - Star conversation
    //
    
    enum StarConversation {
        struct Request {
            let id: String
        }
    }
    
    //
    // MARK: - Unstar conversation
    //
    
    enum UnstarConversation {
        struct Request {
            let id: String
        }
    }
    
    //
    // MARK: - Conversations did select
    //
    
    enum ConversationsDidSelect {
        struct Request {
            let ids: [String]
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
