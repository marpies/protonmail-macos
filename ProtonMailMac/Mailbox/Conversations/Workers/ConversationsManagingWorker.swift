//
//  ConversationsManagingWorker.swift
//  ProtonMailMac
//
//  Created by Marcel Piešťanský on 10.10.2021.
//  Copyright © 2021 marpies. All rights reserved.
//

import Foundation
import Swinject

protocol ConversationsManagingWorkerDelegate: ConversationsLoadingDelegate {
    func conversationDidUpdate(conversation: Conversations.Conversation.Response, index: Int)
}

class ConversationsManagingWorker: ConversationOpsProcessingDelegate {
    
    let userId: String
    
    private let resolver: Resolver
    private let apiService: ApiService
    private var opsService: ConversationOpsProcessing
    
    private var loadingWorker: ConversationsLoading?
    private var conversationUpdateObserver: NSObjectProtocol?
    
    var conversations: [Conversations.Conversation.Response]?
    
    weak var delegate: ConversationsManagingWorkerDelegate?
    
    init(userId: String, apiService: ApiService, resolver: Resolver) {
        self.userId = userId
        self.resolver = resolver
        self.apiService = apiService
        self.opsService = resolver.resolve(ConversationOpsProcessing.self, arguments: userId, apiService)!
        self.opsService.delegate = self
        
        self.addObservers()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(optional: self.conversationUpdateObserver)
    }
    
    //
    // MARK: - Public
    //
    
    func setup(labelId: String) {
        // Create new worker if needed
        if self.loadingWorker == nil || self.loadingWorker!.labelId != labelId {
            self.loadingWorker?.delegate = nil
            
            self.loadingWorker = self.resolver.resolve(ConversationsLoading.self, arguments: labelId, self.userId, self.apiService)
            self.loadingWorker?.delegate = self.delegate
        }
    }
    
    func updateConversationStar(id: String, isOn: Bool) {
        self.opsService.label(conversationIds: [id], label: MailboxSidebar.Item.starred.id, apply: isOn, includingMessages: true)
        
        // Dispatch notification for other sections (e.g. conversation details)
        // This worker will react to this notification as well
        let notification: Conversations.Notifications.ConversationUpdate = Conversations.Notifications.ConversationUpdate(conversationId: id)
        NotificationCenter.default.post(notification)
    }
    
    func updateCachedConversations(_ conversations: [Conversations.Conversation.Response]) {
        self.loadingWorker?.updateCachedConversations(conversations)
    }
    
    func loadConversations(completion: @escaping (Bool) -> Void) {
        self.loadingWorker?.loadConversations(completion: completion)
    }
    
    func loadCachedConversations(completion: @escaping ([Conversations.Conversation.Response]) -> Void) {
        self.loadingWorker?.loadCachedConversations(completion: completion)
    }
    
    func loadCachedConversations(updatedConversationIds: Set<String>?) {
        self.loadingWorker?.loadCachedConversations(updatedConversationIds: updatedConversationIds)
    }
    
    func cancelLoad() {
        self.loadingWorker?.delegate = nil
        self.loadingWorker = nil
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
    
    private func refreshConversation(id: String) {
        guard let (conversation, index) = self.loadingWorker?.updateConversation(id: id) else { return }
        
        self.delegate?.conversationDidUpdate(conversation: conversation, index: index)
    }
    
}
