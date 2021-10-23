//
//  ConversationsManagingWorker.swift
//  ProtonMailMac
//
//  Created by Marcel Piešťanský on 10.10.2021.
//  Copyright © 2021 marpies. All rights reserved.
//

import Foundation
import Swinject

protocol ConversationsManagingWorkerDelegate: ConversationsLoadingDelegate, ConversationOpsProcessingDelegate {
    func conversationDidUpdate(conversation: Conversations.Conversation.Response, index: Int)
    func conversationsDidRefresh(response: Conversations.RefreshConversations.Response)
}

class ConversationsManagingWorker {
    
    let userId: String
    
    private let resolver: Resolver
    private let apiService: ApiService
    private var opsService: ConversationOpsProcessing
    
    private var loadingWorker: ConversationsLoading?
    private var conversationUpdateObserver: NSObjectProtocol?
    private var conversationsUpdateObserver: NSObjectProtocol?
    
    var conversations: [Conversations.Conversation.Response]?
    
    weak var delegate: ConversationsManagingWorkerDelegate? {
        didSet {
            self.opsService.delegate = self.delegate
        }
    }
    
    init(userId: String, apiService: ApiService, resolver: Resolver) {
        self.userId = userId
        self.resolver = resolver
        self.apiService = apiService
        self.opsService = resolver.resolve(ConversationOpsProcessing.self, arguments: userId, apiService)!
        
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
        let success: Bool = self.opsService.label(conversationIds: [id], label: MailboxSidebar.Item.starred.id, apply: isOn)
        
        guard success else { return }
        
        // Dispatch notification for other sections (e.g. conversation details)
        // This worker will react to this notification as well
        let notification: Conversations.Notifications.ConversationUpdate = Conversations.Notifications.ConversationUpdate(conversationId: id)
        notification.post()
    }
    
    func updateConversationsLabel(ids: [String], labelId: String, apply: Bool) {
        let success: Bool = self.opsService.label(conversationIds: ids, label: labelId, apply: apply)
        
        guard success else { return }
        
        // Dispatch notification for other sections (e.g. conversation details)
        // This worker will react to this notification as well
        if ids.count > 1 {
            let notification: Conversations.Notifications.ConversationsUpdate = Conversations.Notifications.ConversationsUpdate(conversationIds: Set(ids))
            notification.post()
        } else if let id = ids.first {
            let notification: Conversations.Notifications.ConversationUpdate = Conversations.Notifications.ConversationUpdate(conversationId: id)
            notification.post()
        }
    }
    
    func moveConversations(ids: [String], toFolder folderId: String) {
        let success: Bool = self.opsService.moveTo(folder: folderId, conversationIds: ids)
        
        guard success else { return }
        
        self.loadingWorker?.loadCachedConversations(updatedConversationIds: Set(ids))
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
    // MARK: - Private
    //
    
    private func addObservers() {
        self.conversationUpdateObserver = NotificationCenter.default.addObserver(forType: Conversations.Notifications.ConversationUpdate.self, object: nil, queue: .main, using: { [weak self] notification in
            guard let weakSelf = self, let conversationId = notification?.conversationId else { return }
            
            weakSelf.refreshConversation(id: conversationId)
        })
        
        self.conversationsUpdateObserver = NotificationCenter.default.addObserver(forType: Conversations.Notifications.ConversationsUpdate.self, object: nil, queue: .main, using: { [weak self] notification in
            guard let weakSelf = self, let conversationIds = notification?.conversationIds else { return }
            
            weakSelf.refreshConversations(ids: conversationIds)
        })
    }
    
    private func refreshConversation(id: String) {
        guard let (conversation, index) = self.loadingWorker?.updateConversation(id: id) else { return }
        
        self.delegate?.conversationDidUpdate(conversation: conversation, index: index)
    }
    
    private func refreshConversations(ids: Set<String>) {
        var conversations: [(Conversations.Conversation.Response, Int)] = []
        var indices: Set<Int> = []
        
        for conversationId in ids {
            guard let (conversation, index) = self.loadingWorker?.updateConversation(id: conversationId) else { continue }
            
            conversations.append((conversation, index))
            indices.insert(index)
        }
        
        guard !conversations.isEmpty else { return }
        
        let indexSet: IndexSet = IndexSet(indices)
        let response: Conversations.RefreshConversations.Response = Conversations.RefreshConversations.Response(conversations: conversations, indexSet: indexSet)
        self.delegate?.conversationsDidRefresh(response: response)
    }
    
}
