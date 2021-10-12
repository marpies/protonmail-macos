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
    
    func updateCachedMessages(_ messages: [Messages.Message.Response])
    
    func loadMessage(id: String) -> Messages.Message.Response?
    func loadMessages(completion: ((Bool) -> Void)?)
    
    /// Updates the model for the message of the given id.
    /// - Returns: Tuple with the message model and the model's index in the list of all messages.
    func updateMessage(id: String) -> (Messages.Message.Response, Int)?
    
    func loadCachedMessages(completion: @escaping ([Messages.Message.Response]) -> Void)
    func loadCachedMessages(updatedMessageIds: Set<String>?)
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
}

class MessagesLoadingWorker: MessagesLoading, MessageDiffing, MessageToModelConverting {
    
    let labelId: String
    
    private let userId: String
    private let resolver: Resolver
    private let apiService: ApiService
    
    /// List of currently loaded messages.
    private var messages: [Messages.Message.Response]?
    
    weak var delegate: MessagesLoadingDelegate?

    init(resolver: Resolver, labelId: String, userId: String, apiService: ApiService) {
        self.resolver = resolver
        self.labelId = labelId
        self.userId = userId
        self.apiService = apiService
    }
    
    //
    // MARK: - Public
    //
    
    func updateCachedMessages(_ messages: [Messages.Message.Response]) {
        self.messages = messages
        
        self.delegate?.cachedMessagesDidLoad(messages)
    }
    
    func loadMessage(id: String) -> Messages.Message.Response? {
        let db: MessagesDatabaseManaging = self.resolver.resolve(MessagesDatabaseManaging.self)!
        
        guard let message = db.loadMessage(id: id) else { return nil }
        
        return self.getMessage(message)
    }
    
    func updateMessage(id: String) -> (Messages.Message.Response, Int)? {
        let db: MessagesDatabaseManaging = self.resolver.resolve(MessagesDatabaseManaging.self)!
        
        guard let index = self.messages?.firstIndex(where: { $0.id == id }),
              let message = db.loadMessage(id: id) else { return nil }
        
        let model: Messages.Message.Response = self.getMessage(message)
        self.messages?[index] = model
        
        return (model, index)
    }
    
    func loadCachedMessages(completion: @escaping ([Messages.Message.Response]) -> Void) {
        let db: MessagesDatabaseManaging = self.resolver.resolve(MessagesDatabaseManaging.self)!
        
        db.fetchMessages(forUser: self.userId, labelId: self.labelId, olderThan: nil, converter: self) { messages in
            completion(messages)
        }
    }
    
    func loadCachedMessages(updatedMessageIds: Set<String>?) {
        self.loadCachedMessages { messages in
            self.dispatchMessages(messages, updatedMessageIds: updatedMessageIds)
        }
    }
    
    func loadMessages(completion: ((Bool) -> Void)?) {
        self.loadMessages(olderThan: nil) { [weak self] (messages, error) in
            guard let weakSelf = self else { return }
            
            if let messages = messages {
                weakSelf.dispatchMessages(messages, updatedMessageIds: nil)
            } else {
                weakSelf.dispatchLoadError(error)
            }
            
            completion?(messages != nil)
        }
    }
    
    //
    // MARK: - Private
    //
    
    private func loadMessages(olderThan lastMessageTime: Date?, completion: @escaping ([Messages.Message.Response]?, NSError?) -> Void) {
        // Fetch messages from the server
        let endTime: TimeInterval = lastMessageTime?.timeIntervalSince1970 ?? 0
        let request = MessagesByLabelRequest(labelID: self.labelId, endTime: endTime)
        
        self.apiService.request(request) { [weak self] (_, responseDict, error) in
            guard let weakSelf = self else { return }
            
            if var messagesArray = responseDict?["Messages"] as? [[String : Any]] {
                // Add user id to every message
                for (index, _) in messagesArray.enumerated() {
                    messagesArray[index]["UserID"] = weakSelf.userId
                }
                
                let db: MessagesDatabaseManaging = weakSelf.resolver.resolve(MessagesDatabaseManaging.self)!
                db.saveMessages(messagesArray, forUser: weakSelf.userId) {
                    weakSelf.loadCachedMessages { messages in
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
    
    private func dispatchMessages(_ models: [Messages.Message.Response], updatedMessageIds: Set<String>?) {
        let oldMessagesOpt = self.messages
        self.messages = models
        
        if let oldMessages = oldMessagesOpt {
            if let response = self.getMessagesDiff(oldMessages: oldMessages, newMessages: models, updatedMessageIds: updatedMessageIds) {
                self.delegate?.messagesDidUpdate(response: response)
            }
        } else {
            self.delegate?.messagesDidLoad(models)
        }
    }
    
    private func dispatchLoadError(_ error: NSError?) {
        let error: NSError = error ?? NSError.unknownError()
        
        let response = Messages.LoadError.Response(error: error)
        self.delegate?.messagesLoadDidFail(response: response)
    }
    
}
