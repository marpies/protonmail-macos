//
//  MailboxManagingWorker.swift
//  ProtonMailMac
//
//  Created by Marcel Piešťanský on 11.10.2021.
//  Copyright © 2021 marpies. All rights reserved.
//

import Foundation
import Swinject

protocol MailboxManagingWorkerDelegate: ConversationsManagingWorkerDelegate, MessagesManagingWorkerDelegate {
    func mailboxLoadDidFail(error: NSError)
    
    /// Called when the mailbox was updated but no actual changes were detected.
    func mailboxDidUpdateWithoutChange()
}

protocol MailboxManaging {
    var userId: String { get }
    var delegate: MailboxManagingWorkerDelegate? { get set }
    
    func loadMailbox(labelId: String, isMessages: Bool)
    
    /// Refreshes the mailbox to check for new messages.
    /// - Parameter eventsOnly: If `true`, only the `/events` endpoint will be queried to check for new messages.
    ///                         If `false`, messages for the current label will be fetched subsequently if no updates
    ///                         are returned by the `/events` endpoint.
    func refreshMailbox(eventsOnly: Bool)
    
    func updateConversationStar(id: String, isOn: Bool, userId: String)
    func updateMessageStar(id: String, isOn: Bool, userId: String)
    func getConversationId(forMessageId id: String) -> String?
}

/// Handles mailbox loading / refreshing for both conversations and individual messages (sent/draft folders).
class MailboxManagingWorker: MailboxManaging, ConversationsManagingWorkerDelegate, MessagesManagingWorkerDelegate, AuthCredentialRefreshing {
    
    private let refreshTimerInterval: TimeInterval = 30
    
    let userId: String
    
    private let resolver: Resolver
    private let usersManager: UsersManager
    
    private var conversationsWorker: ConversationsManagingWorker?
    private var messagesWorker: MessagesManagingWorker?
    
    /// Timer triggering an auto-refresh.
    private var timer: Timer?
    
    /// `true` if the current label is meant to display messages instead of conversations (e.g. sent, drafts).
    private var isBrowsingMessages: Bool = false
    
    private(set) var labelId: String?
    
    private(set) var auth: AuthCredential?
    private(set) var apiService: ApiService?
    
    weak var delegate: MailboxManagingWorkerDelegate?

    init(userId: String, resolver: Resolver) {
        self.userId = userId
        self.resolver = resolver
        self.usersManager = resolver.resolve(UsersManager.self)!
        
        self.apiService = resolver.resolve(ApiService.self)!
        self.apiService?.authDelegate = self
        
        self.conversationsWorker = ConversationsManagingWorker(userId: userId, apiService: self.apiService!, resolver: resolver)
        self.conversationsWorker?.delegate = self
        
        self.messagesWorker = MessagesManagingWorker(userId: userId, apiService: self.apiService!, resolver: resolver)
        self.messagesWorker?.delegate = self
    }
    
    //
    // MARK: - Public
    //
    
    func loadMailbox(labelId: String, isMessages: Bool) {
        guard let user = self.usersManager.activeUser else {
            fatalError("Unexpected application state.")
        }
        
        self.removeTimer()
        
        self.auth = user.auth
        
        self.labelId = labelId
        self.isBrowsingMessages = isMessages
        
        if self.isBrowsingMessages {
            self.conversationsWorker?.cancelLoad()
            
            self.messagesWorker?.setup(labelId: labelId)
            self.messagesWorker?.loadCachedMessages { messages in
                if !messages.isEmpty {
                    self.messagesWorker?.updateCachedMessages(messages)
                }
                
                self.refreshMailbox(eventsOnly: false)
            }
        } else {
            self.messagesWorker?.cancelLoad()
            
            self.conversationsWorker?.setup(labelId: labelId)
            self.conversationsWorker?.loadCachedConversations { conversations in
                if !conversations.isEmpty {
                    self.conversationsWorker?.updateCachedConversations(conversations)
                }
                
                self.refreshMailbox(eventsOnly: false)
            }
        }
    }
    
    func refreshMailbox(eventsOnly: Bool) {
        guard let labelId = self.labelId else { return }
        
        self.removeTimer()
        
        let userEventsDb: UserEventsDatabaseManaging = self.resolver.resolve(UserEventsDatabaseManaging.self)!
        let eventId: String = userEventsDb.getLastEventId(forUser: self.userId)
        
        // Invalid event id
        if eventId.isEmpty || eventId == "0" {
            let request = EventLatestIDRequest()
            self.apiService?.request(request, completion: { [weak self] (response: EventLatestIDResponse) in
                guard let weakSelf = self else { return }
                
                if !response.eventID.isEmpty {
                    weakSelf.cleanUpAndLoadMailbox(eventId: response.eventID)
                } else {
                    PMLog.D("Error loading EVENT ID \(String(describing: response.error))")
                    weakSelf.setRefreshTimer()
                    weakSelf.dispatchLoadError(response.error)
                }
            })
        } else {
            let service: UserEventsProcessing = self.resolver.resolve(UserEventsProcessing.self)!
            service.fetchEvents(forLabel: labelId, userId: self.userId) { [weak self] (response: UserEventsResponse) in
                guard let weakSelf = self else { return }
                
                switch response {
                case .cleanUp(let eventId):
                    weakSelf.cleanUpAndLoadMailbox(eventId: eventId)
                case .success(let json):
                    // Check if there are any message updates
                    guard json["Conversations"] != nil || json["Messages"] != nil else {
                        // todo may have Notices
                        // todo check "More"
                        weakSelf.delegate?.mailboxDidUpdateWithoutChange()
                        
                        if eventsOnly {
                            weakSelf.setRefreshTimer()
                        } else {
                            weakSelf.loadMailbox()
                        }
                        return
                    }
                    
                    let updatedConversationIds: Set<String>? = json["UpdatedConversations"] as? Set<String>
                    let updatedMessageIds: Set<String>? = json["UpdatedMessages"] as? Set<String>
                    
                    // Post notification about updated conversation ids
                    if let ids = updatedConversationIds {
                        let notification: Conversations.Notifications.ConversationsUpdate = Conversations.Notifications.ConversationsUpdate(conversationIds: ids)
                        notification.post()
                    }
                    
                    // Post notification about updated message ids
                    if let ids = updatedMessageIds {
                        let notification: Messages.Notifications.MessagesUpdate = Messages.Notifications.MessagesUpdate(messageIds: ids)
                        notification.post()
                    }
                    
                    weakSelf.loadCachedMailbox(updatedConversationIds: updatedConversationIds, updatedMessageIds: updatedMessageIds)
                case .error(let error):
                    PMLog.D("Error loading events \(error)")
                    weakSelf.setRefreshTimer()
                    weakSelf.dispatchLoadError(error)
                }
            }
        }
    }
    
    func updateConversationStar(id: String, isOn: Bool, userId: String) {
        self.conversationsWorker?.updateConversationStar(id: id, isOn: isOn, userId: userId)
    }
    
    func updateMessageStar(id: String, isOn: Bool, userId: String) {
        self.messagesWorker?.updateMessageStar(id: id, isOn: isOn, userId: userId)
    }
    
    func getConversationId(forMessageId id: String) -> String? {
        return self.messagesWorker?.getConversationId(forMessageId: id)
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
    // MARK: - Conversations managing delegate
    //
    
    func cachedConversationsDidLoad(_ conversations: [Conversations.Conversation.Response]) {
        self.delegate?.cachedConversationsDidLoad(conversations)
    }
    
    func conversationsDidLoad(_ conversations: [Conversations.Conversation.Response]) {
        self.delegate?.conversationsDidLoad(conversations)
        
        self.setRefreshTimer()
    }
    
    func conversationsDidUpdate(response: Conversations.UpdateConversations.Response) {
        self.delegate?.conversationsDidUpdate(response: response)
        
        self.setRefreshTimer()
    }
    
    func conversationsLoadDidFail(response: Conversations.LoadError.Response) {
        self.delegate?.mailboxLoadDidFail(error: response.error)
        
        self.setRefreshTimer()
    }
    
    func conversationDidUpdate(conversation: Conversations.Conversation.Response, index: Int) {
        self.delegate?.conversationDidUpdate(conversation: conversation, index: index)
    }
    
    //
    // MARK: - Messages managing delegate
    //
    
    func cachedMessagesDidLoad(_ messages: [Messages.Message.Response]) {
        self.delegate?.cachedMessagesDidLoad(messages)
    }
    
    func messagesDidLoad(_ messages: [Messages.Message.Response]) {
        self.delegate?.messagesDidLoad(messages)
        
        self.setRefreshTimer()
    }
    
    func messagesDidUpdate(response: Messages.UpdateMessages.Response) {
        self.delegate?.messagesDidUpdate(response: response)
        
        self.setRefreshTimer()
    }
    
    func messagesLoadDidFail(response: Messages.LoadError.Response) {
        self.delegate?.mailboxLoadDidFail(error: response.error)
        
        self.setRefreshTimer()
    }
    
    func messageDidUpdate(message: Messages.Message.Response, index: Int) {
        self.delegate?.messageDidUpdate(message: message, index: index)
    }
    
    //
    // MARK: - Private
    //
    
    /// Loads the current items in the mailbox for the given label directly without querying the events endpoint.
    private func loadMailbox() {
        self.loadMailbox(completion: nil)
    }
    
    private func loadMailbox(completion: (() -> Void)?) {
        let completionBlock: ((Bool) -> Void) = { [weak self] (success) in
            if success {
                self?.loadMailboxCounts()
            }
            
            completion?()
        }
        
        if self.isBrowsingMessages {
            self.messagesWorker?.loadMessages(completion: completionBlock)
        } else {
            self.conversationsWorker?.loadConversations(completion: completionBlock)
        }
    }
    
    private func loadCachedMailbox(updatedConversationIds: Set<String>?, updatedMessageIds: Set<String>?) {
        if self.isBrowsingMessages {
            self.messagesWorker?.loadCachedMessages(updatedMessageIds: updatedMessageIds)
        } else {
            self.conversationsWorker?.loadCachedConversations(updatedConversationIds: updatedConversationIds)
        }
    }
    
    private func cleanUpAndLoadMailbox(eventId: String) {
        let messagesDb: ConversationsDatabaseManaging = self.resolver.resolve(ConversationsDatabaseManaging.self)!
        messagesDb.cleanConversations(forUser: self.userId, removeDrafts: true).done { _ in
            let labelUpdateDb: LabelUpdateDatabaseManaging = self.resolver.resolve(LabelUpdateDatabaseManaging.self)!
            labelUpdateDb.removeUpdateTime(forUser: self.userId)
            
            self.loadMailbox { [weak self] in
                guard let weakSelf = self else { return }
                
                let userEventsDb: UserEventsDatabaseManaging = weakSelf.resolver.resolve(UserEventsDatabaseManaging.self)!
                userEventsDb.updateEventId(forUser: weakSelf.userId, eventId: eventId, completion: nil)
            }
        }.cauterize()
    }
    
    private func dispatchLoadError(_ error: NSError?) {
        let error: NSError = error ?? NSError.unknownError()
        
        self.delegate?.mailboxLoadDidFail(error: error)
    }
    
    //
    // MARK: - Timer
    //
    
    private func setRefreshTimer() {
        guard self.timer == nil else { return }
        
        self.timer = Timer.scheduledTimer(withTimeInterval: self.refreshTimerInterval, repeats: true, block: { [weak self] (_) in
            self?.refreshMailbox(eventsOnly: true)
        })
    }
    
    private func removeTimer() {
        self.timer?.invalidate()
        self.timer = nil
    }
    
    //
    // MARK: - Mailbox counts (conversation + messages)
    //
    
    private func loadMailboxCounts() {
        let worker: MailboxCountLoadingWorker = MailboxCountLoadingWorker(apiService: self.apiService!)
        worker.load { [weak self] counts in
            guard let weakSelf = self, let counts = counts else { return }
            
            let db: LabelUpdateDatabaseManaging = weakSelf.resolver.resolve(LabelUpdateDatabaseManaging.self)!
            db.updateCounts(userId: weakSelf.userId, counts: counts)
        }
    }
    
}
