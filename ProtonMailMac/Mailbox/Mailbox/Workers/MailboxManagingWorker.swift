//
//  MailboxManagingWorker.swift
//  ProtonMailMac
//
//  Created by Marcel Piešťanský on 11.10.2021.
//  Copyright © 2021 marpies. All rights reserved.
//

import Foundation
import Swinject

protocol MailboxManagingWorkerDelegate: AnyObject {
    func mailboxLoadDidFail(error: NSError)
    
    /// Called when the cache is loaded before querying the server.
    /// - Parameter conversations: List of conversations loaded from the cache.
    func cachedConversationsDidLoad(_ conversations: [Conversations.Conversation.Response])
    
    /// Called when the server response is received.
    /// - Parameter conversations: List of conversations as returned by the server.
    func conversationsDidLoad(_ conversations: [Conversations.Conversation.Response])
    
    /// Called when an update to the existing list of conversations is received.
    /// - Parameter response: Model representing the changes made to the latest list of conversations.
    func conversationsDidUpdate(response: Conversations.UpdateConversations.Response)
    
    /// Called when a single conversation in the existing list was updated.
    /// - Parameters:
    ///   - conversation: The updated conversation model.
    ///   - index: The index of the conversation in the list.
    func conversationDidUpdate(conversation: Conversations.Conversation.Response, index: Int)
    
    /// Called when multiple conversations in the existing list were updated.
    /// - Parameter response: Model representing the updated conversation models.
    func conversationsDidRefresh(response: Conversations.RefreshConversations.Response)
    
    /// Called when the cache is loaded before querying the server.
    /// - Parameter messages: List of messages loaded from the cache.
    func cachedMessagesDidLoad(_ messages: [Messages.Message.Response])
    
    /// Called when the server response is received.
    /// - Parameter messages: List of messages as returned by the server.
    func messagesDidLoad(_ messages: [Messages.Message.Response])
    
    /// Called when an update to the existing list of messages is received.
    /// - Parameter response: Model representing the changes made to the latest list of messages.
    func messagesDidUpdate(response: Messages.UpdateMessages.Response)
    
    /// Called when a single message in the existing list was updated.
    /// - Parameters:
    ///   - message: The updated message model.
    ///   - index: The index of the message in the list.
    func messageDidUpdate(message: Messages.Message.Response, index: Int)
    
    /// Called when multiple messages in the existing list were updated.
    /// - Parameter response: Model representing the updated message models.
    func messagesDidRefresh(response: Messages.RefreshMessages.Response)
    
    /// Called when the mailbox was updated but no actual changes were detected.
    func mailboxDidUpdateWithoutChange()
    
    /// Called when operations on conversations or messages (e.g. applying labels) were completed server side.
    /// Now would be a good time to fetch the `/events` endpoint to ensure proper sync between local and server data.
    func mailboxOperationsProcessingDidComplete()
    
    func mailboxPageCountDidUpdate(response: Mailbox.PageCountUpdate.Response)
}

protocol MailboxManaging {
    var userId: String { get }
    var delegate: MailboxManagingWorkerDelegate? { get set }
    
    func loadMailbox(labelId: String, isMessages: Bool)
    
    func loadPage(_ type: Mailbox.Page)
    
    /// Refreshes the mailbox to check for new messages.
    /// - Parameter eventsOnly: If `true`, only the `/events` endpoint will be queried to check for new messages.
    ///                         If `false`, messages for the current label will be fetched subsequently if no updates
    ///                         are returned by the `/events` endpoint.
    func refreshMailbox(eventsOnly: Bool)
    
    func updateConversationStar(id: String, isOn: Bool)
    func updateMessageStar(id: String, isOn: Bool)
    
    func updateConversationsLabel(ids: [String], labelId: String, apply: Bool)
    func updateMessagesLabel(ids: [String], labelId: String, apply: Bool)
    
    func getConversationId(forMessageId id: String) -> String?
    
    func moveConversations(ids: [String], toFolder folder: String)
    func moveMessages(ids: [String], toFolder folder: String)
    
    func cancelLoad()
}

/// Handles mailbox loading / refreshing for both conversations and individual messages (sent/draft folders).
class MailboxManagingWorker: MailboxManaging, ConversationsManagingWorkerDelegate, MessagesManagingWorkerDelegate, AuthCredentialRefreshing {
    
    private let refreshTimerInterval: TimeInterval = 30
    
    let userId: String
    
    private let resolver: Resolver
    private let usersManager: UsersManager
    
    private var conversationsWorker: ConversationsManagingWorker?
    private var messagesWorker: MessagesManagingWorker?
    
    private var conversationCountsObserver: NSObjectProtocol?
    
    /// Timer triggering an auto-refresh.
    private var timer: Timer?
    
    /// `true` if the current label is meant to display messages instead of conversations (e.g. sent, drafts).
    private var isBrowsingMessages: Bool = false
    
    /// Flag to track whether we should load the conversation counts (only on initial load).
    private var isInitialLoad: Bool = true
    
    /// Current page of messages (or conversations) loaded (zero based).
    private var currentPage: Int = 0
    
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
        
        self.addObservers()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(optional: self.conversationCountsObserver)
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
        self.currentPage = 0
        
        self.loadPageCounts()
        
        if self.isBrowsingMessages {
            self.conversationsWorker?.cancelLoad()
            
            self.messagesWorker?.setup(labelId: labelId)
            self.messagesWorker?.loadCachedMessages(page: self.currentPage) { messages in
                if !messages.isEmpty {
                    self.messagesWorker?.updateCachedMessages(messages)
                }
                
                self.refreshMailbox(eventsOnly: false)
            }
        } else {
            self.messagesWorker?.cancelLoad()
            
            self.conversationsWorker?.setup(labelId: labelId)
            self.conversationsWorker?.loadCachedConversations(page: self.currentPage) { conversations in
                if !conversations.isEmpty {
                    self.conversationsWorker?.updateCachedConversations(conversations)
                }
                
                self.refreshMailbox(eventsOnly: false)
            }
        }
    }
    
    func loadPage(_ type: Mailbox.Page) {
        switch type {
        case .first:
            self.currentPage = 0
        case .previous:
            assert(self.currentPage > 0)
            self.currentPage -= 1
        case .next:
            self.currentPage += 1
        case .last:
            self.currentPage = self.numPages
        case .specific(let page):
            guard let pageInt = Int(page) else { return }
            
            self.currentPage = pageInt
        }
        
        self.loadPageCounts()
        
        if self.isBrowsingMessages {
            self.messagesWorker?.loadCachedMessages(page: self.currentPage) { messages in
                if !messages.isEmpty {
                    self.messagesWorker?.updateCachedMessages(messages)
                }
            }
        } else {
            self.conversationsWorker?.loadCachedConversations(page: self.currentPage) { conversations in
                // Show cached items
                if !conversations.isEmpty {
                    self.conversationsWorker?.updateCachedConversations(conversations)
                }
                // No cached items, fetch server data
                else {
                    self.loadMailbox()
                }
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
    
    func moveConversations(ids: [String], toFolder folder: String) {
        self.conversationsWorker?.moveConversations(ids: ids, page: self.currentPage, toFolder: folder)
        
        self.loadPageCounts()
        
        self.conversationsWorker?.loadCachedConversations(page: self.currentPage, updatedConversationIds: Set(ids))
    }
    
    func updateConversationStar(id: String, isOn: Bool) {
        self.conversationsWorker?.updateConversationStar(id: id, isOn: isOn)
        
        self.loadPageCounts()
        
        self.conversationsWorker?.loadCachedConversations(page: self.currentPage, updatedConversationIds: [id])
    }
    
    func updateConversationsLabel(ids: [String], labelId: String, apply: Bool) {
        self.conversationsWorker?.updateConversationsLabel(ids: ids, labelId: labelId, apply: apply)
        
        self.loadPageCounts()
        
        self.conversationsWorker?.loadCachedConversations(page: self.currentPage, updatedConversationIds: Set(ids))
    }
    
    func moveMessages(ids: [String], toFolder folder: String) {
        self.messagesWorker?.moveMessages(ids: ids, page: self.currentPage, toFolder: folder)
        
        self.loadPageCounts()
        
        self.messagesWorker?.loadCachedMessages(page: self.currentPage, updatedMessageIds: Set(ids))
    }
    
    func updateMessageStar(id: String, isOn: Bool) {
        self.messagesWorker?.updateMessageStar(id: id, isOn: isOn)
    }
    
    func updateMessagesLabel(ids: [String], labelId: String, apply: Bool) {
        self.messagesWorker?.updateMessagesLabel(ids: ids, labelId: labelId, apply: apply)
    }
    
    func getConversationId(forMessageId id: String) -> String? {
        return self.messagesWorker?.getConversationId(forMessageId: id)
    }
    
    func cancelLoad() {
        self.conversationsWorker?.cancelLoad()
        self.messagesWorker?.cancelLoad()
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
    
    func conversationsDidRefresh(response: Conversations.RefreshConversations.Response) {
        self.delegate?.conversationsDidRefresh(response: response)
    }
    
    func labelsDidUpdateForConversations(ids: [String], labelId: String) {
        self.delegate?.mailboxOperationsProcessingDidComplete()
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
    
    func messagesDidRefresh(response: Messages.RefreshMessages.Response) {
        self.delegate?.messagesDidRefresh(response: response)
    }
    
    func labelsDidUpdateForMessages(ids: [String], labelId: String) {
        self.delegate?.mailboxOperationsProcessingDidComplete()
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
                if let weakSelf = self, weakSelf.isInitialLoad {
                    weakSelf.isInitialLoad = false
                    weakSelf.loadMailboxCounts()
                }
            }
            
            completion?()
        }
        
        if self.isBrowsingMessages {
            self.messagesWorker?.loadMessages(page: self.currentPage, completion: completionBlock)
        } else {
            self.conversationsWorker?.loadConversations(page: self.currentPage, completion: completionBlock)
        }
    }
    
    private func loadCachedMailbox(updatedConversationIds: Set<String>?, updatedMessageIds: Set<String>?) {
        if self.isBrowsingMessages {
            self.messagesWorker?.loadCachedMessages(page: self.currentPage, updatedMessageIds: updatedMessageIds)
        } else {
            self.conversationsWorker?.loadCachedConversations(page: self.currentPage, updatedConversationIds: updatedConversationIds)
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
    
    private func loadPageCounts() {
        let numPages: Int = self.numPages
        if self.currentPage > 0 && self.currentPage >= numPages {
            self.currentPage = numPages - 1
        }
        
        // Page is zero based (i.e. first page = 0), add +1 for the presentation layer
        let response: Mailbox.PageCountUpdate.Response = Mailbox.PageCountUpdate.Response(currentPage: self.currentPage + 1, numPages: self.numPages)
        self.delegate?.mailboxPageCountDidUpdate(response: response)
    }
    
    private var numPages: Int {
        guard let labelId = self.labelId else {
            fatalError("Unexpected application state.")
        }
        
        let db: LabelUpdateDatabaseManaging = self.resolver.resolve(LabelUpdateDatabaseManaging.self)!
        let total: Int = db.getTotalCount(for: labelId, userId: self.userId)
        let numPages: Int = Int(ceil(Float(total) / Float(Mailbox.numItemsPerPage)))
        
        return numPages
    }
    
    private func addObservers() {
        self.conversationCountsObserver = NotificationCenter.default.addObserver(forType: Main.Notifications.ConversationCountsUpdate.self, object: nil, queue: .main, using: { [weak self] notification in
            guard let weakSelf = self, let notification = notification,
                  let userId = weakSelf.usersManager.activeUser?.userId,
                  userId == notification.userId else { return }
            
            weakSelf.loadPageCounts()
        })
    }
    
}
