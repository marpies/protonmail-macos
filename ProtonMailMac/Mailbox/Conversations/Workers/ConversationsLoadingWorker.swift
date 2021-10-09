//
//  ConversationsLoadingWorker.swift
//  ProtonMailMac
//
//  Created by Marcel Piešťanský on 16.09.2021.
//  Copyright © 2021 marpies. All rights reserved.
//

import Foundation
import Swinject

protocol ConversationsLoading {
    var labelId: String { get }
    var delegate: ConversationsLoadingDelegate? { get set }
    
    func loadConversations()
    func loadConversation(id: String) -> Conversations.Conversation.Response?
    
    /// Updates the model for the conversation of the given id.
    /// - Returns: Tuple with the conversation model and the model's index in the list of all conversations.
    func updateConversation(id: String) -> (Conversations.Conversation.Response, Int)?
}

protocol ConversationsLoadingDelegate: AnyObject {
    /// Called when the cache is loaded before querying the server.
    /// - Parameter conversations: List of conversations loaded from the cache.
    func cachedConversationsDidLoad(_ conversations: [Conversations.Conversation.Response])
    
    /// Called when the server response is received.
    /// - Parameter conversations: List of conversations as returned by the server.
    func conversationsDidLoad(_ conversations: [Conversations.Conversation.Response])
    
    /// Called when an update to the existing list of conversations is received.
    /// - Parameter response: Model representing the changes made to the latest list of conversations.
    func conversationsDidUpdate(response: Conversations.UpdateConversations.Response)
    
    /// Called when an error is encountered when loading the conversations.
    /// - Parameter response:
    func conversationsLoadDidFail(response: Conversations.LoadError.Response)
    
    /// Called when the conversations were updated but no actual changes were detected.
    func conversationsDidUpdateWithoutChange()
}

class ConversationsLoadingWorker: ConversationsLoading, ConversationDiffing, ConversationToModelConverting, AuthCredentialRefreshing {
    
    private let refreshTimerInterval: TimeInterval = 30
    
    let labelId: String
    
    private let userId: String
    private let resolver: Resolver
    private let usersManager: UsersManager
    
    /// List of currently loaded conversations.
    private var conversations: [Conversations.Conversation.Response]?
    
    /// Timer triggering an auto-refresh.
    private var timer: Timer?
    
    private(set) var auth: AuthCredential?
    private(set) var apiService: ApiService?
    
    weak var delegate: ConversationsLoadingDelegate?
    
    init(resolver: Resolver, labelId: String, userId: String) {
        self.resolver = resolver
        self.labelId = labelId
        self.userId = userId
        self.usersManager = resolver.resolve(UsersManager.self)!
        self.apiService = self.resolver.resolve(ApiService.self)!
        self.apiService?.authDelegate = self
    }
    
    deinit {
        self.timer?.invalidate()
    }
    
    //
    // MARK: - Public
    //
    
    func loadConversations() {
        guard let user = self.usersManager.getUser(forId: self.userId) else {
            fatalError("Unexpected application state.")
        }
        
        self.auth = user.auth
        
        // Load local cache
        self.loadCachedConversations { conversations in
            if !conversations.isEmpty {
                self.conversations = conversations
            }
            
            self.delegate?.cachedConversationsDidLoad(conversations)
            
            let userEventsDb: UserEventsDatabaseManaging = self.resolver.resolve(UserEventsDatabaseManaging.self)!
            let eventId: String = userEventsDb.getLastEventId(forUser: self.userId)
            
            // Invalid event id
            if eventId.isEmpty || eventId == "0" {
                // todo load event id first
                let request = EventLatestIDRequest()
                self.apiService?.request(request, completion: { [weak self] (response: EventLatestIDResponse) in
                    guard let weakSelf = self else { return }
                    
                    if !response.eventID.isEmpty {
                        weakSelf.cleanUpAndLoadConversations(eventId: response.eventID)
                    } else {
                        PMLog.D("Error loading EVENT ID \(response.error)")
                        weakSelf.setRefreshTimer()
                        weakSelf.dispatchLoadError(response.error)
                    }
                })
            } else {
                let service: UserEventsProcessing = self.resolver.resolve(UserEventsProcessing.self)!
                service.fetchEvents(forLabel: self.labelId, userId: self.userId) { [weak self] (response: UserEventsResponse) in
                    guard let weakSelf = self else { return }
                    
                    switch response {
                    case .cleanUp(let eventId):
                        weakSelf.cleanUpAndLoadConversations(eventId: eventId)
                    case .success(let json):
                        // Check if there are any message updates
                        guard json["Conversations"] != nil else {
                            // todo may have Notices
                            // todo check "More"
                            weakSelf.delegate?.conversationsDidUpdateWithoutChange()
                            
                            weakSelf.fetchConversations()
                            return
                        }
                        
                        let updatedConversationIds: Set<String>? = json["UpdatedConversations"] as? Set<String>
                        
                        weakSelf.loadCachedConversations { conversations in
                            weakSelf.dispatchConversations(conversations, updatedConversationIds: updatedConversationIds)
                        }
                    case .error(let error):
                        PMLog.D("Error loading events \(error)")
                        weakSelf.setRefreshTimer()
                        weakSelf.dispatchLoadError(error)
                    }
                }
            }
        }
    }
    
    func loadConversation(id: String) -> Conversations.Conversation.Response? {
        let db: ConversationsDatabaseManaging = self.resolver.resolve(ConversationsDatabaseManaging.self)!
        
        guard let conversation = db.loadConversation(id: id) else { return nil }
        
        return self.getConversation(conversation)
    }
    
    func updateConversation(id: String) -> (Conversations.Conversation.Response, Int)? {
        let db: ConversationsDatabaseManaging = self.resolver.resolve(ConversationsDatabaseManaging.self)!
        
        guard let index = self.conversations?.firstIndex(where: { $0.id == id }),
              let conversation = db.loadConversation(id: id) else { return nil }
        
        let model: Conversations.Conversation.Response = self.getConversation(conversation)
        self.conversations?[index] = model
        
        return (model, index)
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
    
    private func fetchConversations() {
        self.loadConversations() { [weak self] (messages, error) in
            guard let weakSelf = self else { return }
            
            weakSelf.setRefreshTimer()
            
            if let messages = messages {
                weakSelf.dispatchConversations(messages, updatedConversationIds: nil)
            } else {
                weakSelf.dispatchLoadError(error)
            }
        }
    }
    
    private func loadCachedConversations(completion: @escaping ([Conversations.Conversation.Response]) -> Void) {
        let db: ConversationsDatabaseManaging = self.resolver.resolve(ConversationsDatabaseManaging.self)!
        
        db.fetchConversations(forUser: self.userId, labelId: self.labelId, converter: self) { conversations in
            completion(conversations)
        }
    }
    
    private func cleanUpAndLoadConversations(eventId: String) {
        let messagesDb: ConversationsDatabaseManaging = self.resolver.resolve(ConversationsDatabaseManaging.self)!
        messagesDb.cleanConversations(forUser: self.userId, removeDrafts: true).done { _ in
            let labelUpdateDb: LabelUpdateDatabaseManaging = self.resolver.resolve(LabelUpdateDatabaseManaging.self)!
            labelUpdateDb.removeUpdateTime(forUser: self.userId)
            
            self.loadConversations { [weak self] (conversations, error) in
                guard let weakSelf = self else { return }
                
                let userEventsDb: UserEventsDatabaseManaging = weakSelf.resolver.resolve(UserEventsDatabaseManaging.self)!
                userEventsDb.updateEventId(forUser: weakSelf.userId, eventId: eventId, completion: nil)
                
                if let conversations = conversations {
                    weakSelf.dispatchConversations(conversations, updatedConversationIds: nil)
                } else {
                    PMLog.D("ERROR LOADING Conversations... \(String(describing: error))")
                    weakSelf.setRefreshTimer()
                    weakSelf.dispatchLoadError(error)
                }
            }
        }.cauterize()
    }
    
    private func loadConversations(completion: @escaping ([Conversations.Conversation.Response]?, NSError?) -> Void) {
        // Fetch conversations from the server
        let request = ConversationsRequest(labelID: self.labelId)
        
        self.apiService?.request(request) { [weak self] (_, responseDict, error) in
            guard let weakSelf = self else { return }
            
            if var conversationsArray = responseDict?["Conversations"] as? [[String : Any]] {
                // Add user id to every conversation
                for (index, _) in conversationsArray.enumerated() {
                    conversationsArray[index]["UserID"] = weakSelf.userId
                }
                
                weakSelf.loadConversationsCounts()
                
                let db: ConversationsDatabaseManaging = weakSelf.resolver.resolve(ConversationsDatabaseManaging.self)!
                db.saveConversations(conversationsArray, forUser: weakSelf.userId) {
                    weakSelf.loadCachedConversations { messages in
                        completion(messages, nil)
                    }
                }
            } else {
                DispatchQueue.main.async {
                    completion(nil, error ?? NSError.unknownError())
                }
            }
        }
    }
    
    private func dispatchConversations(_ models: [Conversations.Conversation.Response], updatedConversationIds: Set<String>?) {
        let oldConversationsOpt = self.conversations
        self.conversations = models
        
        if let oldConversations = oldConversationsOpt {
            let response = self.getConversationsDiff(oldConversations: oldConversations, newConversations: models, updatedConversationIds: updatedConversationIds)
            self.delegate?.conversationsDidUpdate(response: response)
        } else {
            self.delegate?.conversationsDidLoad(models)
        }
        
        self.setRefreshTimer()
    }
    
    private func dispatchLoadError(_ error: NSError?) {
        let error: NSError = error ?? NSError.unknownError()
        
        let response = Conversations.LoadError.Response(error: error)
        self.delegate?.conversationsLoadDidFail(response: response)
    }
    
    //
    // MARK: - Conversations count
    //
    
    private func loadConversationsCounts() {
        let request: ConversationsCountRequest = ConversationsCountRequest()
        
        self.apiService?.request(request, completion: { (response: ConversationsCountResponse) in
            guard let counts = response.conversationCounts else { return }
            
            let db: LabelUpdateDatabaseManaging = self.resolver.resolve(LabelUpdateDatabaseManaging.self)!
            db.updateCounts(userId: self.userId, counts: counts)
        })
    }
    
    //
    // MARK: - Timer
    //
    
    private func setRefreshTimer() {
        guard self.timer == nil else { return }
        
//        self.timer = Timer.scheduledTimer(withTimeInterval: self.refreshTimerInterval, repeats: true, block: { [weak self] (_) in
//            self?.refreshMessagesIfNeeded()
//        })
    }
    
    private func refreshMessagesIfNeeded() {
        guard let user = self.usersManager.getUser(forId: userId) else { return }
        
        self.auth = user.auth
        
        self.loadConversations()
    }
    
}
