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
}

class ConversationsWorker: ConversationsLoadingDelegate {
    
	private let resolver: Resolver
    private let usersManager: UsersManager
    
    private var loadingWorker: ConversationsLoading?
    
    private var activeUserId: String? {
        return self.usersManager.activeUser?.userId
    }
    
    /// The last loaded label. Nil if messages have not been loaded yet.
    var labelId: String?

	weak var delegate: ConversationsWorkerDelegate?

	init(resolver: Resolver) {
		self.resolver = resolver
        self.usersManager = resolver.resolve(UsersManager.self)!
	}

    func loadConversations(request: Conversations.LoadConversations.Request) {
        guard let user = self.usersManager.activeUser else {
            fatalError("Unexpected application state.")
        }
        
        let labelId: String = request.labelId
        self.labelId = labelId
        
        self.loadConversations(forLabel: labelId, userId: user.userId)
    }
    
    func starConversation(request: Conversations.StarConversation.Request) {
        // todo conversations ops service
    }
    
    func unstarConversation(request: Conversations.UnstarConversation.Request) {
        
    }
    
    func processConversationsSelection(request: Conversations.ConversationsDidSelect.Request) {
        
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
    }
    
    func conversationsLoadDidFail(response: Conversations.LoadError.Response) {
        self.delegate?.conversationsLoadDidFail(response: response)
    }
    
    func conversationsDidUpdateWithoutChange() {
        self.delegate?.conversationsDidUpdateWithoutChange()
    }
    
    //
    // MARK: - Private
    //
    
    private func loadConversations(forLabel labelId: String, userId: String) {
        // Create new worker if needed
        if self.loadingWorker == nil || self.loadingWorker!.labelId != labelId {
            self.loadingWorker?.delegate = nil
            
            self.loadingWorker = self.resolver.resolve(ConversationsLoading.self, arguments: labelId, userId)
            self.loadingWorker?.delegate = self
        }
        
        self.loadingWorker?.loadConversations()
    }
    
}
