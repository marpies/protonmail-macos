//
//  MessagesLoadingWorker.swift
//  ProtonMailMac
//
//  Created by Marcel Piešťanský on 10.09.2021.
//  Copyright © 2021 marpies. All rights reserved.
//

import Foundation
import Swinject

protocol MessagesLoading {
    var labelId: String { get }
    var delegate: MessagesLoadingDelegate? { get set }
    
    func loadMessages(olderThan lastMessageTime: Date?)
    func loadMessage(id: String) -> Messages.Message.Response?
}

protocol MessagesLoadingDelegate: AnyObject {
    /// Called when the cache is loaded before querying the server.
    /// - Parameter messages: List of messages loaded from the cache.
    func cachedMessagesDidLoad(_ messages: [Messages.Message.Response])
    
    /// Called when the server response is received.
    /// - Parameter messages: List of messages as returned by the server.
    func messagesDidLoad(_ messages: [Messages.Message.Response])
    
    /// Called when an update to the existing list of messages is received.
    /// - Parameter response: Model representing the changes made to the latest list of messages.
    func messagesDidUpdate(response: Messages.UpdateMessages.Response)
    
    /// Called when an error is encountered when loading the messages.
    /// - Parameter response:
    func messagesLoadDidFail(response: Messages.LoadError.Response)
    
    /// Called when the messages were updated but no actual changes were detected.
    func messagesDidUpdateWithoutChange()
}

class MessagesLoadingWorker: MessagesLoading, MessageDiffing, MessageToModelConverting, AuthCredentialRefreshing {
    
    private let refreshTimerInterval: TimeInterval = 30
    
    let labelId: String
    
    private let userId: String
    private let resolver: Resolver
    private let usersManager: UsersManager
    
    /// List of currently loaded messages.
    private var messages: [Messages.Message.Response]?
    
    /// Timer triggering an auto-refresh.
    private var timer: Timer?
    
    private(set) var auth: AuthCredential?
    private(set) var apiService: ApiService?
    
    weak var delegate: MessagesLoadingDelegate?

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
    
    func loadMessages(olderThan lastMessageTime: Date?) {
        guard let user = self.usersManager.getUser(forId: self.userId) else {
            fatalError("Unexpected application state.")
        }
        
        self.auth = user.auth
        
        // Load local cache
        self.loadCachedMessages(olderThan: lastMessageTime) { messages in
            let models: [Messages.Message.Response] = messages.map { self.getMessage($0) }
            
            if !messages.isEmpty {
                self.messages = messages.map { self.getMessage($0) }
            }
            
            self.delegate?.cachedMessagesDidLoad(models)
            
            let userEventsDb: UserEventsDatabaseManaging = self.resolver.resolve(UserEventsDatabaseManaging.self)!
            let eventId: String = userEventsDb.getLastEventId(forUser: self.userId)
            
            // Invalid event id
            if eventId.isEmpty || eventId == "0" {
                // todo load event id first
                let request = EventLatestIDRequest()
                self.apiService?.request(request, completion: { [weak self] (response: EventLatestIDResponse) in
                    guard let weakSelf = self else { return }
                    
                    if !response.eventID.isEmpty {
                        weakSelf.cleanUpAndLoadMessages(eventId: response.eventID)
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
                        weakSelf.cleanUpAndLoadMessages(eventId: eventId)
                    case .success(let json):
                        // Check if there are any message updates
                        guard json["Messages"] != nil else {
                            // todo may have Notices
                            // todo check "More"
                            weakSelf.delegate?.messagesDidUpdateWithoutChange()
                            
                            weakSelf.fetchMessages()
                            return
                        }
                        
                        let updatedMessageIds: Set<String>? = json["UpdatedMessages"] as? Set<String>
                        
                        weakSelf.loadCachedMessages(olderThan: lastMessageTime) { messages in
                            weakSelf.dispatchMessages(messages, updatedMessageIds: updatedMessageIds)
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
    
    func loadMessage(id: String) -> Messages.Message.Response? {
        let db: MessagesDatabaseManaging = self.resolver.resolve(MessagesDatabaseManaging.self)!
        
        guard let message = db.loadMessage(id: id) else { return nil }
        
        return self.getMessage(message)
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
    
    private func fetchMessages() {
        self.loadMessages(olderThan: nil) { [weak self] (messages, error) in
            guard let weakSelf = self else { return }
            
            weakSelf.setRefreshTimer()
            
            if let messages = messages {
                weakSelf.dispatchMessages(messages, updatedMessageIds: nil)
            } else {
                weakSelf.dispatchLoadError(error)
            }
        }
    }
    
    private func loadCachedMessages(olderThan lastMessageTime: Date?, completion: @escaping ([Message]) -> Void) {
        let db: MessagesDatabaseManaging = self.resolver.resolve(MessagesDatabaseManaging.self)!
        
        db.fetchMessages(forUser: self.userId, labelId: self.labelId, olderThan: lastMessageTime) { messages in
            completion(messages)
        }
    }
    
    private func cleanUpAndLoadMessages(eventId: String) {
        let messagesDb: MessagesDatabaseManaging = self.resolver.resolve(MessagesDatabaseManaging.self)!
        messagesDb.cleanMessages(forUser: self.userId, removeDrafts: true).done { _ in
            let labelUpdateDb: LabelUpdateDatabaseManaging = self.resolver.resolve(LabelUpdateDatabaseManaging.self)!
            labelUpdateDb.removeUpdateTime(forUser: self.userId)
            
            self.loadMessages(olderThan: nil) { [weak self] (messages, error) in
                guard let weakSelf = self else { return }
                
                let userEventsDb: UserEventsDatabaseManaging = weakSelf.resolver.resolve(UserEventsDatabaseManaging.self)!
                userEventsDb.updateEventId(forUser: weakSelf.userId, eventId: eventId, completion: nil)
                
                if let models = messages?.map({ weakSelf.getMessage($0) }) {
                    weakSelf.dispatchMessages(models, updatedMessageIds: nil)
                } else {
                    PMLog.D("ERROR LOADING MESSAGES... \(error)")
                    weakSelf.setRefreshTimer()
                    weakSelf.dispatchLoadError(error)
                }
            }
        }.cauterize()
    }
    
    private func loadMessages(olderThan lastMessageTime: Date?, completion: @escaping ([Message]?, NSError?) -> Void) {
        // Fetch messages from the server
        let endTime: TimeInterval = lastMessageTime?.timeIntervalSince1970 ?? 0
        let request = MessagesByLabelRequest(labelID: self.labelId, endTime: endTime)
        
        self.apiService?.request(request) { [weak self] (_, responseDict, error) in
            guard let weakSelf = self else { return }
            
            if var messagesArray = responseDict?["Messages"] as? [[String : Any]] {
                // Add user id to every message
                for (index, _) in messagesArray.enumerated() {
                    messagesArray[index]["UserID"] = weakSelf.userId
                }
                
                let db: MessagesDatabaseManaging = weakSelf.resolver.resolve(MessagesDatabaseManaging.self)!
                db.saveMessages(messagesArray, forUser: weakSelf.userId) {
                    weakSelf.loadCachedMessages(olderThan: lastMessageTime) { messages in
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
    
    private func dispatchMessages(_ messages: [Message], updatedMessageIds: Set<String>?) {
        let models: [Messages.Message.Response] = messages.map { self.getMessage($0) }
        self.dispatchMessages(models, updatedMessageIds: updatedMessageIds)
    }
    
    private func dispatchMessages(_ models: [Messages.Message.Response], updatedMessageIds: Set<String>?) {
        let oldMessagesOpt = self.messages
        self.messages = models
        
        if let oldMessages = oldMessagesOpt {
            let response = self.getMessagesDiff(oldMessages: oldMessages, newMessages: models, updatedMessageIds: updatedMessageIds)
            self.delegate?.messagesDidUpdate(response: response)
        } else {
            self.delegate?.messagesDidLoad(models)
        }
        
        self.setRefreshTimer()
    }
    
    private func dispatchLoadError(_ error: NSError?) {
        let error: NSError = error ?? NSError.unknownError()
        
        let response = Messages.LoadError.Response(error: error)
        self.delegate?.messagesLoadDidFail(response: response)
    }
    
    //
    // MARK: - Timer
    //
    
    private func setRefreshTimer() {
        guard self.timer == nil else { return }
        
        self.timer = Timer.scheduledTimer(withTimeInterval: self.refreshTimerInterval, repeats: true, block: { [weak self] (_) in
            self?.refreshMessagesIfNeeded()
        })
    }
    
    private func refreshMessagesIfNeeded() {
        guard let user = self.usersManager.getUser(forId: userId) else { return }
        
        self.auth = user.auth
        
        self.loadMessages(olderThan: nil)
    }
    
}
