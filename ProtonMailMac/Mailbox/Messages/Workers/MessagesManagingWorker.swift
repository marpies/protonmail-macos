//
//  MessagesManagingWorker.swift
//  ProtonMailMac
//
//  Created by Marcel Piešťanský on 10.10.2021.
//  Copyright © 2021 marpies. All rights reserved.
//

import Foundation
import Swinject

protocol MessagesManagingWorkerDelegate: MessagesLoadingDelegate {
    func messageDidUpdate(message: Messages.Message.Response, index: Int)
}

class MessagesManagingWorker: MessageOpsProcessingDelegate, ConversationLabelStatusChecking {
    
    let userId: String
    
    private let resolver: Resolver
    private let apiService: ApiService
    
    private var loadingWorker: MessagesLoading?
    private var messageUpdateObserver: NSObjectProtocol?
    private var messagesUpdateObserver: NSObjectProtocol?
    
    weak var delegate: MessagesManagingWorkerDelegate?
    
    init(userId: String, apiService: ApiService, resolver: Resolver) {
        self.userId = userId
        self.resolver = resolver
        self.apiService = apiService
        
        self.addObservers()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(optional: self.messageUpdateObserver)
        NotificationCenter.default.removeObserver(optional: self.messagesUpdateObserver)
    }
    
    //
    // MARK: - Public
    //
    
    func setup(labelId: String) {
        // Create new worker if needed
        if self.loadingWorker == nil || self.loadingWorker!.labelId != labelId {
            self.loadingWorker?.delegate = nil
            
            self.loadingWorker = self.resolver.resolve(MessagesLoading.self, arguments: labelId, self.userId, self.apiService)
            self.loadingWorker?.delegate = self.delegate
        }
    }
    
    func updateMessageStar(id: String, isOn: Bool) {
        // Get conversation starred status before updating
        let conversation: Conversation? = self.getConversation(forMessageId: id)
        let isConversationStarred: Bool = conversation?.contains(label: .starred) ?? false
        
        var service: MessageOpsProcessing = self.resolver.resolve(MessageOpsProcessing.self, argument: self.userId)!
        service.delegate = self
        service.label(messageIds: [id], label: MailboxSidebar.Item.starred.id, apply: isOn)
        
        // Check if the conversation star changed and dispatch notification if needed for other scenes to reflect this change
        if let c = conversation {
            self.checkConversationLabel(label: .starred, conversation: c, hasLabel: isConversationStarred)
        }
        
        // Dispatch notification for other sections (e.g. conversation details)
        // This worker will react to this notification as well
        let notification: Messages.Notifications.MessageUpdate = Messages.Notifications.MessageUpdate(messageId: id)
        notification.post()
    }
    
    func getConversationId(forMessageId id: String) -> String? {
        return self.getConversation(forMessageId: id)?.conversationID
    }
    
    func updateCachedMessages(_ messages: [Messages.Message.Response]) {
        self.loadingWorker?.updateCachedMessages(messages)
    }
    
    func loadMessages(completion: @escaping (Bool) -> Void) {
        self.loadingWorker?.loadMessages(completion: completion)
    }
    
    func loadCachedMessages(completion: @escaping ([Messages.Message.Response]) -> Void) {
        self.loadingWorker?.loadCachedMessages(completion: completion)
    }
    
    func loadCachedMessages(updatedMessageIds: Set<String>?) {
        self.loadingWorker?.loadCachedMessages(updatedMessageIds: updatedMessageIds)
    }
    
    func cancelLoad() {
        self.loadingWorker?.delegate = nil
        self.loadingWorker = nil
    }
    
    //
    // MARK: - Message ops delegate
    //
    
    func labelsDidUpdateForMessages(ids: [String], labelId: String) {
        // todo refresh
    }
    
    //
    // MARK: - Private
    //
    
    private func getConversation(forMessageId id: String) -> Conversation? {
        let db: MessagesDatabaseManaging = self.resolver.resolve(MessagesDatabaseManaging.self)!
        return db.loadMessage(id: id)?.conversation
    }
    
    private func addObservers() {
        self.messageUpdateObserver = NotificationCenter.default.addObserver(forType: Messages.Notifications.MessageUpdate.self, object: nil, queue: .main, using: { [weak self] notification in
            guard let weakSelf = self, let messageId = notification?.messageId else { return }

            weakSelf.refreshMessage(id: messageId)
        })
        
        self.messagesUpdateObserver = NotificationCenter.default.addObserver(forType: Messages.Notifications.MessagesUpdate.self, object: nil, queue: .main, using: { [weak self] notification in
            guard let weakSelf = self, let messageIds = notification?.messageIds else { return }
            
            for messageId in messageIds {
                weakSelf.refreshMessage(id: messageId)
            }
        })
    }
    
    private func refreshMessage(id: String) {
        guard let (message, index) = self.loadingWorker?.updateMessage(id: id) else { return }

        self.delegate?.messageDidUpdate(message: message, index: index)
    }
    
}
