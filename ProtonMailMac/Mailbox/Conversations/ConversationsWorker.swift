//
//  ConversationsWorker.swift
//  ProtonMailMac
//
//  Created by Marcel Piešťanský on 16.09.2021.
//  Copyright (c) 2021 marpies. All rights reserved.
//

import Foundation
import Swinject

protocol ConversationsWorkerDelegate: AnyObject {
    func conversationsDidLoad(response: Conversations.LoadConversations.Response)
    func conversationsDidUpdate(response: Conversations.UpdateConversations.Response)
    func conversationDidUpdate(response: Conversations.UpdateConversation.Response)
    func conversationsLoadDidFail(response: Conversations.LoadError.Response)
    func conversationsDidUpdateWithoutChange()
    func conversationShouldLoad(response: Conversations.LoadConversation.Response)
}

class ConversationsWorker: ConversationsLoadingDelegate, ConversationOpsProcessingDelegate {
    
	private let resolver: Resolver
    private let usersManager: UsersManager
    
    private var loadingWorker: ConversationsLoading?
    
    private var activeUserId: String? {
        return self.usersManager.activeUser?.userId
    }
    
    private var conversationUpdateObserver: NSObjectProtocol?
    
    /// The last loaded label. Nil if messages have not been loaded yet.
    var labelId: String?

	weak var delegate: ConversationsWorkerDelegate?

	init(resolver: Resolver) {
		self.resolver = resolver
        self.usersManager = resolver.resolve(UsersManager.self)!
        
        self.addObservers()
	}

    func loadConversations(request: Conversations.LoadConversations.Request) {
        guard let user = self.usersManager.activeUser else {
            fatalError("Unexpected application state.")
        }
        
        let labelId: String = request.labelId
        self.labelId = labelId
        
        self.loadConversations(forLabel: labelId, userId: user.userId)
    }
    
    func updateConversationStar(request: Conversations.UpdateConversationStar.Request) {
        guard let userId = self.activeUserId else { return }
        
        var service: ConversationOpsProcessing = self.resolver.resolve(ConversationOpsProcessing.self, argument: userId)!
        service.delegate = self
        service.label(conversationIds: [request.id], label: MailboxSidebar.Item.starred.id, apply: request.isOn, includingMessages: true)
        
        // Dispatch notification for other sections (e.g. conversation details)
        // This worker will react to this notification as well
        let notification: Conversations.Notifications.ConversationUpdate = Conversations.Notifications.ConversationUpdate(conversationId: request.id)
        NotificationCenter.default.post(notification)
    }
    
    func processConversationsSelection(request: Conversations.ConversationsDidSelect.Request) {
        // Load conversation
        if request.ids.count == 1 {
            let response: Conversations.LoadConversation.Response = Conversations.LoadConversation.Response(id: request.ids[0])
            self.delegate?.conversationShouldLoad(response: response)
        }
    }
    
    func reloadConversations() {
        guard let labelId = self.labelId,
              let user = self.usersManager.activeUser else { return }
        
        self.loadConversations(forLabel: labelId, userId: user.userId)
    }
    
    //
    // MARK: - Conversations loading delegate
    //
    
    func cachedConversationsDidLoad(_ conversations: [Conversations.Conversation.Response]) {
        let response = Conversations.LoadConversations.Response(conversations: conversations, isServerResponse: false)
        self.delegate?.conversationsDidLoad(response: response)
    }
    
    func conversationsDidLoad(_ conversations: [Conversations.Conversation.Response]) {
        let response = Conversations.LoadConversations.Response(conversations: conversations, isServerResponse: true)
        self.delegate?.conversationsDidLoad(response: response)
    }
    
    func conversationsDidUpdate(response: Conversations.UpdateConversations.Response) {
        self.delegate?.conversationsDidUpdate(response: response)
        
        let ids: [String] = response.conversations.map { $0.id }
        let notification: Conversations.Notifications.ConversationsUpdate = Conversations.Notifications.ConversationsUpdate(conversationIds: ids)
        notification.post()
    }
    
    func conversationsLoadDidFail(response: Conversations.LoadError.Response) {
        self.delegate?.conversationsLoadDidFail(response: response)
    }
    
    func conversationsDidUpdateWithoutChange() {
        self.delegate?.conversationsDidUpdateWithoutChange()
    }
    
    //
    // MARK: - Conversation ops delegate
    //
    
    func labelsDidUpdateForConversations(ids: [String], labelId: String) {
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
    
    private func loadConversations(forLabel labelId: String, userId: String) {
        // Create new worker if needed
        if self.loadingWorker == nil || self.loadingWorker!.labelId != labelId {
            self.loadingWorker?.delegate = nil
            
            self.loadingWorker = self.resolver.resolve(ConversationsLoading.self, arguments: labelId, userId)
            self.loadingWorker?.delegate = self
        }
        
        self.loadingWorker?.loadConversations()
    }
    
    private func refreshConversation(id: String) {
        guard let (conversation, index) = self.loadingWorker?.updateConversation(id: id) else { return }
        
        let response: Conversations.UpdateConversation.Response = Conversations.UpdateConversation.Response(conversation: conversation, index: index)
        self.delegate?.conversationDidUpdate(response: response)
    }
    
}
