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
    
    func updateCachedConversations(_ conversations: [Conversations.Conversation.Response])
    func loadConversation(id: String) -> Conversations.Conversation.Response?
    
    /// Updates the model for the conversation of the given id.
    /// - Returns: Tuple with the conversation model and the model's index in the list of all conversations.
    func updateConversation(id: String) -> (Conversations.Conversation.Response, Int)?
    
    func loadConversations(page: Int, completion: @escaping (Bool) -> Void)
    func loadCachedConversations(page: Int, completion: @escaping ([Conversations.Conversation.Response]) -> Void)
    func loadCachedConversations(page: Int, updatedConversationIds: Set<String>?)
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
}

class ConversationsLoadingWorker: ConversationsLoading, ConversationDiffing, ConversationToModelConverting {
    
    let labelId: String
    
    private let userId: String
    private let resolver: Resolver
    private let usersManager: UsersManager
    private let apiService: ApiService
    
    /// List of currently loaded conversations.
    private var conversations: [Conversations.Conversation.Response]?
    
    /// The page this worker is currently loading.
    private var currentPage: Int = 0
    
    weak var delegate: ConversationsLoadingDelegate?
    
    init(resolver: Resolver, labelId: String, userId: String, apiService: ApiService) {
        self.resolver = resolver
        self.labelId = labelId
        self.userId = userId
        self.usersManager = resolver.resolve(UsersManager.self)!
        self.apiService = apiService
    }
    
    //
    // MARK: - Public
    //
    
    func updateCachedConversations(_ conversations: [Conversations.Conversation.Response]) {
        self.conversations = conversations
        
        self.delegate?.cachedConversationsDidLoad(conversations)
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
    
    func loadConversations(page: Int, completion: @escaping (Bool) -> Void) {
        self.currentPage = page
        
        self.loadConversations(page: page) { [weak self] (conversations, error) in
            guard let weakSelf = self, weakSelf.currentPage == page else { return }
            
            if let conversations = conversations {
                weakSelf.dispatchConversations(conversations, updatedConversationIds: nil)
            } else {
                weakSelf.dispatchLoadError(error)
            }
            
            completion(conversations != nil)
        }
    }
    
    func loadCachedConversations(page: Int, completion: @escaping ([Conversations.Conversation.Response]) -> Void) {
        self.currentPage = page
        
        let db: ConversationsDatabaseManaging = self.resolver.resolve(ConversationsDatabaseManaging.self)!
        
        db.fetchConversations(forUser: self.userId, labelId: self.labelId, page: page, converter: self) { [weak self] (conversations) in
            guard let weakSelf = self, weakSelf.currentPage == page else { return }
            
            completion(conversations)
        }
    }
    
    func loadCachedConversations(page: Int, updatedConversationIds: Set<String>?) {
        self.loadCachedConversations(page: page) { [weak self] (conversations) in
            self?.dispatchConversations(conversations, updatedConversationIds: updatedConversationIds)
        }
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
    
    private func loadConversations(page: Int, completion: @escaping ([Conversations.Conversation.Response]?, NSError?) -> Void) {
        // Fetch conversations from the server
        let request: ConversationsRequest = ConversationsRequest(labelID: self.labelId, page: page)
        
        self.apiService.request(request) { [weak self] (_, responseDict, error) in
            guard let weakSelf = self else { return }
            
            if var conversationsArray = responseDict?["Conversations"] as? [[String : Any]] {
                // Add user id to every conversation
                for (index, _) in conversationsArray.enumerated() {
                    conversationsArray[index]["UserID"] = weakSelf.userId
                }
                
                let db: ConversationsDatabaseManaging = weakSelf.resolver.resolve(ConversationsDatabaseManaging.self)!
                db.saveConversations(conversationsArray, forUser: weakSelf.userId) {
                    weakSelf.loadCachedConversations(page: page) { conversations in
                        completion(conversations, nil)
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
            if let response = self.getConversationsDiff(oldConversations: oldConversations, newConversations: models, updatedConversationIds: updatedConversationIds) {
                self.delegate?.conversationsDidUpdate(response: response)
            }
        } else {
            self.delegate?.conversationsDidLoad(models)
        }
    }
    
    private func dispatchLoadError(_ error: NSError?) {
        let error: NSError = error ?? NSError.unknownError()
        
        let response = Conversations.LoadError.Response(error: error)
        self.delegate?.conversationsLoadDidFail(response: response)
    }
    
}
