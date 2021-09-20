//
//  ConversationDetailsWorker.swift
//  ProtonMailMac
//
//  Created by Marcel Piešťanský on 17.09.2021.
//  Copyright (c) 2021 marpies. All rights reserved.
//

import Foundation
import Swinject

protocol ConversationDetailsWorkerDelegate: AnyObject {
    func conversationDidLoad(response: ConversationDetails.Load.Response)
    func conversationLoadDidFail(response: ConversationDetails.LoadError.Response)
}

class ConversationDetailsWorker: AuthCredentialRefreshing, MessageToModelConverting, ConversationToModelConverting {

	private let resolver: Resolver
    private let usersManager: UsersManager
    
    private(set) var auth: AuthCredential?
    private(set) var apiService: ApiService?
    
    /// Previously loaded converation id.
    private var conversationId: String?
    
    /// Label id for the model conversion, use "all mail" to have info about folders parsed.
    let labelId: String = MailboxSidebar.Item.allMail.id

	weak var delegate: ConversationDetailsWorkerDelegate?

	init(resolver: Resolver) {
		self.resolver = resolver
        self.usersManager = resolver.resolve(UsersManager.self)!
        self.apiService = resolver.resolve(ApiService.self)
        self.apiService?.authDelegate = self
	}
    
    func loadConversation(request: ConversationDetails.Load.Request) {
        self.conversationId = request.id
        
        self.loadConversation(id: request.id)
    }
    
    func reloadConversation() {
        guard let conversationId = self.conversationId else { return }
        
        self.loadConversation(id: conversationId)
    }
    
    //
    // MARK: - Auth delegate
    //
    
    func onForceUpgrade() {
        //
    }
    
    func sessionDidRevoke() {
        //
    }
    
    func authCredentialDidRefresh() {
        self.usersManager.save()
    }
    
    //
    // MARK: - Private
    //
    
    private func loadConversation(id: String) {
        guard let user = self.usersManager.activeUser else {
            fatalError("Unexpected application state.")
        }
        
        let conversationsDb: ConversationsDatabaseManaging = self.resolver.resolve(ConversationsDatabaseManaging.self)!
        
        guard let conversationObject = conversationsDb.loadConversation(id: id) else { return }
        
        let hasCachedMessages: Bool = conversationObject.messages.count > 0
        
        // If we have cached messages, provide those for now
        if hasCachedMessages {
            let model: ConversationDetails.Conversation.Response = self.getConversationWithMessages(conversationObject)
            let response: ConversationDetails.Load.Response = ConversationDetails.Load.Response(conversation: model)
            self.delegate?.conversationDidLoad(response: response)
        }
        
        // Also fetch messages for the conversation from the server
        self.auth = user.auth
        let userId: String = user.userId
        
        let request = ConversationByIdRequest(conversationId: id)
        self.apiService?.request(request, completion: { (response: ConversationByIdResponse) in
            if let conversation = response.conversation, let messages = response.messages {
                // Save conversation
                conversationsDb.saveConversations([conversation], forUser: userId) {
                    // Save conversation messages
                    let messagesDb: MessagesDatabaseManaging = self.resolver.resolve(MessagesDatabaseManaging.self)!
                    messagesDb.saveMessages(messages, forUser: userId) {
                        // Make sure we are still showing the conversation we requested
                        guard self.conversationId == id else { return }
                        
                        let model: ConversationDetails.Conversation.Response = self.getConversationWithMessages(conversationObject)
                        let response: ConversationDetails.Load.Response = ConversationDetails.Load.Response(conversation: model)
                        self.delegate?.conversationDidLoad(response: response)
                    }
                }
            } else {
                // Make sure we are still showing the conversation we requested
                guard self.conversationId == id else { return }
                
                let model: ConversationDetails.Conversation.Response = self.getConversationWithMessages(conversationObject)
                let response: ConversationDetails.LoadError.Response = ConversationDetails.LoadError.Response(conversation: model, hasCachedMessages: hasCachedMessages)
                self.delegate?.conversationLoadDidFail(response: response)
            }
        })
    }
    
    private func getConversationWithMessages(_ conversation: Conversation) -> ConversationDetails.Conversation.Response {
        let model: Conversations.Conversation.Response = self.getConversation(conversation)
        
        let messageModels: [Messages.Message.Response]
        
        if let messages = conversation.messages.allObjects as? [Message], !messages.isEmpty {
            messageModels = messages.map { self.getMessage($0) }.sorted(by: { m1, m2 in
                return m1.time.date < m2.time.date
            })
        } else {
            messageModels = []
        }
        
        return ConversationDetails.Conversation.Response(conversation: model, messages: messageModels)
    }

}
