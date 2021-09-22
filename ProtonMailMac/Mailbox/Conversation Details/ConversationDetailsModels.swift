//
//  ConversationDetailsModels.swift
//  ProtonMailMac
//
//  Created by Marcel Piešťanský on 17.09.2021.
//  Copyright (c) 2021 marpies. All rights reserved.
//

import Foundation

enum ConversationDetails {
    
    enum Conversation {
        class Response {
            let conversation: Conversations.Conversation.Response
            let messages: [Messages.Message.Response]

            init(conversation: Conversations.Conversation.Response, messages: [Messages.Message.Response]) {
                self.conversation = conversation
                self.messages = messages
            }
        }
        
        class ViewModel {
            let title: String
            let starIcon: Messages.Star.ViewModel
            let labels: [Messages.Label.ViewModel]?
            let messages: [Messages.Message.ViewModel]

            init(title: String, starIcon: Messages.Star.ViewModel, labels: [Messages.Label.ViewModel]?, messages: [Messages.Message.ViewModel]) {
                self.title = title
                self.starIcon = starIcon
                self.labels = labels
                self.messages = messages
            }
        }
    }

	//
	// MARK: - Load
	//

	enum Load {
		struct Request {
            let id: String
		}

		class Response {
            let conversation: ConversationDetails.Conversation.Response

            init(conversation: ConversationDetails.Conversation.Response) {
                self.conversation = conversation
            }
		}

		class ViewModel {
            let conversation: ConversationDetails.Conversation.ViewModel

            init(conversation: ConversationDetails.Conversation.ViewModel) {
                self.conversation = conversation
            }
		}
	}
    
    //
    // MARK: - Load error
    //
    
    enum LoadError {
        class Response {
            let conversation: ConversationDetails.Conversation.Response
            let hasCachedMessages: Bool

            init(conversation: ConversationDetails.Conversation.Response, hasCachedMessages: Bool) {
                self.conversation = conversation
                self.hasCachedMessages = hasCachedMessages
            }
        }
        
        class ViewModel {
            let conversation: ConversationDetails.Conversation.ViewModel
            let message: String
            let button: String

            init(conversation: ConversationDetails.Conversation.ViewModel, message: String, button: String) {
                self.conversation = conversation
                self.message = message
                self.button = button
            }
        }
    }
    
    //
    // MARK: - Update message star
    //
    
    enum UpdateMessageStar {
        struct Request {
            let id: String
            let isOn: Bool
        }
    }
    
    //
    // MARK: - Update conversation star
    //
    
    enum UpdateConversationStar {
        struct Request {
            let isOn: Bool
        }
    }
    
    //
    // MARK: - Update message
    //
    
    enum UpdateMessage {
        class Response {
            let message: Messages.Message.Response

            init(message: Messages.Message.Response) {
                self.message = message
            }
        }
        
        class ViewModel {
            let message: Messages.Message.ViewModel

            init(message: Messages.Message.ViewModel) {
                self.message = message
            }
        }
    }
    
    //
    // MARK: - Update conversation
    //
    
    enum UpdateConversation {
        class Response {
            let conversation: ConversationDetails.Conversation.Response

            init(conversation: ConversationDetails.Conversation.Response) {
                self.conversation = conversation
            }
        }
        
        class ViewModel {
            let conversation: ConversationDetails.Conversation.ViewModel
            
            init(conversation: ConversationDetails.Conversation.ViewModel) {
                self.conversation = conversation
            }
        }
    }
    
}
