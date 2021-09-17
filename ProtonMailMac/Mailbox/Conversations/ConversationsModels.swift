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
        class Response {
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
