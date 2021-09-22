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
    func conversationMessageDidUpdate(response: ConversationDetails.UpdateMessage.Response)
    func conversationDidUpdate(response: ConversationDetails.UpdateConversation.Response)
}

class ConversationDetailsWorker: AuthCredentialRefreshing, MessageToModelConverting, ConversationToModelConverting, MessageOpsProcessingDelegate, ConversationOpsProcessingDelegate {

	private let resolver: Resolver
    private let usersManager: UsersManager
    
    private(set) var auth: AuthCredential?
    private(set) var apiService: ApiService?
    
    /// Previously loaded converation id.
    private var conversationId: String?
    
    private var conversationUpdateObserver: NSObjectProtocol?
    
    private var activeUserId: String? {
        return self.usersManager.activeUser?.userId
    }
    
    /// Label id for the model conversion, use "all mail" to have info about folders parsed.
    let labelId: String = MailboxSidebar.Item.allMail.id

	weak var delegate: ConversationDetailsWorkerDelegate?

	init(resolver: Resolver) {
		self.resolver = resolver
        self.usersManager = resolver.resolve(UsersManager.self)!
        self.apiService = resolver.resolve(ApiService.self)
        self.apiService?.authDelegate = self
        
        self.addObservers()
	}
    
    func loadConversation(request: ConversationDetails.Load.Request) {
        self.conversationId = request.id
        
        self.loadConversation(id: request.id)
    }
    
    func reloadConversation() {
        guard let conversationId = self.conversationId else { return }
        
        self.loadConversation(id: conversationId)
    }
    
    func updateMessageStar(request: ConversationDetails.UpdateMessageStar.Request) {
        guard let userId = self.activeUserId else { return }
        
        var service: MessageOpsProcessing = self.resolver.resolve(MessageOpsProcessing.self, argument: userId)!
        service.delegate = self
        service.label(messageIds: [request.id], label: MailboxSidebar.Item.starred.id, apply: request.isOn)
        
        self.refreshMessage(id: request.id)
        
        // Check if the conversation itself should be starred/unstarred
        self.checkConversationStar()
    }
    
    func updateConversationStar(request: ConversationDetails.UpdateConversationStar.Request) {
        guard let userId = self.activeUserId, let id = self.conversationId else { return }
        
        var service: ConversationOpsProcessing = self.resolver.resolve(ConversationOpsProcessing.self, argument: userId)!
        service.delegate = self
        service.label(conversationIds: [id], label: MailboxSidebar.Item.starred.id, apply: request.isOn, includingMessages: true)
        
        // Dispatch notification for other sections (e.g. list of conversations)
        // This worker will react to this notification as well
        let notification: Conversations.Notifications.ConversationUpdate = Conversations.Notifications.ConversationUpdate(conversationId: id)
        NotificationCenter.default.post(notification)
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
    // MARK: - Conversation ops delegate
    //
    
    func labelsDidUpdateForConversations(ids: [String], labelId: String) {
        // todo refresh
    }
    
    //
    // MARK: - Message ops processing delegate
    //
    
    func labelsDidUpdateForMessages(ids: [String], labelId: String) {
        // todo refresh
    }
    
    //
    // MARK: - Private
    //
    
    private func addObservers() {
        self.conversationUpdateObserver = NotificationCenter.default.addObserver(forType: Conversations.Notifications.ConversationUpdate.self, object: nil, queue: .main, using: { [weak self] notification in
            guard let weakSelf = self, let conversationId = notification?.conversationId else { return }
            
            weakSelf.refreshConversation(id: conversationId)
        })
    }
    
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
    
    private func refreshMessage(id: String) {
        let db: MessagesDatabaseManaging = self.resolver.resolve(MessagesDatabaseManaging.self)!
        
        guard let messageObject = db.loadMessage(id: id) else { return }
        
        let message: Messages.Message.Response = self.getMessage(messageObject)
        let response: ConversationDetails.UpdateMessage.Response = ConversationDetails.UpdateMessage.Response(message: message)
        self.delegate?.conversationMessageDidUpdate(response: response)
    }
    
    private func checkConversationStar() {
        guard let id = self.conversationId, let userId = self.activeUserId else { return }
        
        let db: ConversationsDatabaseManaging = self.resolver.resolve(ConversationsDatabaseManaging.self)!
        
        guard let conversation = db.loadConversation(id: id), let messages = conversation.messages as? Set<Message> else { return }
        
        let isStarred: Bool = conversation.contains(label: .starred)
        var shouldBeStarred: Bool = false
        for message in messages {
            if message.contains(label: .starred) {
                shouldBeStarred = true
                break
            }
        }
        
        var updatedConversation: Conversation?
        
        // Remove star if is starred and should NOT be starred
        if isStarred && !shouldBeStarred {
            print(" removing star from conversation")
            updatedConversation = db.updateLabel(conversationIds: [id], label: MailboxSidebar.Item.starred.id, apply: false, includingMessages: false, userId: userId)?.first
        }
        // Add star if is NOT starred and should be starred
        else if !isStarred && shouldBeStarred {
            print(" adding star to conversation")
            updatedConversation = db.updateLabel(conversationIds: [id], label: MailboxSidebar.Item.starred.id, apply: true, includingMessages: false, userId: userId)?.first
        }
        
        if updatedConversation != nil {
            // Dispatch notification for other sections (e.g. list of conversations)
            // This worker will react to this notification as well
            let notification: Conversations.Notifications.ConversationUpdate = Conversations.Notifications.ConversationUpdate(conversationId: id)
            NotificationCenter.default.post(notification)
        }
    }
    
    private func refreshConversation(id: String) {
        guard self.conversationId == id else { return }
        
        let db: ConversationsDatabaseManaging = self.resolver.resolve(ConversationsDatabaseManaging.self)!
        
        guard let conversation = db.loadConversation(id: id) else { return }
        
        self.refreshConversation(conversation)
    }
    
    private func refreshConversation(_ conversation: Conversation) {
        let model: ConversationDetails.Conversation.Response = self.getConversationWithMessages(conversation)
        let response = ConversationDetails.UpdateConversation.Response(conversation: model)
        self.delegate?.conversationDidUpdate(response: response)
    }

}
