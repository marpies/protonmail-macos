//
//  MessagesWorker.swift
//  ProtonMailMac
//
//  Created by Marcel Piešťanský on 05.09.2021.
//  Copyright (c) 2021 marpies. All rights reserved.
//

import Foundation
import Swinject
import AppKit
import PromiseKit

protocol MessagesWorkerDelegate: AnyObject {
    func messagesDidLoad(response: Messages.LoadMessages.Response)
    func messagesDidUpdate(response: Messages.UpdateMessages.Response)
    func messagesLoadDidFail(response: Messages.LoadError.Response)
    func messagesDidUpdateWithoutChange()
}

class MessagesWorker: MessagesLoadingDelegate {

    private let resolver: Swinject.Resolver
    private let usersManager: UsersManager
    
    /// Date of the last loaded message. Nil if messages have not been loaded yet.
    private var lastMessageTime: Date?
    
    private var loadingWorker: MessagesLoading?
    private var messages: [Messages.Message.Response]?
    
    /// The last loaded label. Nil if messages have not been loaded yet.
    var labelId: String?

	weak var delegate: MessagesWorkerDelegate?

    init(resolver: Swinject.Resolver) {
		self.resolver = resolver
        self.usersManager = resolver.resolve(UsersManager.self)!
	}

	func loadMessages(request: Messages.LoadMessages.Request) {
        guard let user = self.usersManager.activeUser else {
            fatalError("Unexpected application state.")
        }
        
        // Current label is different from the one we want to load,
        // cancel the last message time
        if let labelId = self.labelId, labelId != request.labelId {
            self.lastMessageTime = nil
        }
        
        let labelId: String = request.labelId
        self.labelId = labelId
        
        self.loadMessages(forLabel: labelId, userId: user.userId, olderThan: nil)
	}
    
    //
    // MARK: - Messages loading delegate
    //
    
    func cachedMessagesDidLoad(_ messages: [Messages.Message.Response]) {
        self.messages = messages
        
        let response = Messages.LoadMessages.Response(messages: messages, isServerResponse: false)
        self.delegate?.messagesDidLoad(response: response)
    }
    
    func messagesDidLoad(_ messages: [Messages.Message.Response]) {
        let response = Messages.LoadMessages.Response(messages: messages, isServerResponse: true)
        self.delegate?.messagesDidLoad(response: response)
    }
    
    func messagesDidUpdate(response: Messages.UpdateMessages.Response) {
        self.delegate?.messagesDidUpdate(response: response)
    }
    
    func messagesLoadDidFail(response: Messages.LoadError.Response) {
        self.delegate?.messagesLoadDidFail(response: response)
    }
    
    func messagesDidUpdateWithoutChange() {
        self.delegate?.messagesDidUpdateWithoutChange()
    }
    
    //
    // MARK: - Private
    //
    
    private func loadMessages(forLabel labelId: String, userId: String, olderThan lastMessageTime: Date?) {
        // Create new worker if needed
        if self.loadingWorker == nil || self.loadingWorker!.labelId != labelId {
            self.loadingWorker?.delegate = nil
            
            self.loadingWorker = self.resolver.resolve(MessagesLoading.self, arguments: labelId, userId)
            self.loadingWorker?.delegate = self
        }
        
        self.loadingWorker?.loadMessages(olderThan: lastMessageTime)
    }

}
