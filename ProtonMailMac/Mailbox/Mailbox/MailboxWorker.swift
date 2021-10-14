//
//  MailboxWorker.swift
//  ProtonMailMac
//
//  Created by Marcel Piešťanský on 16.09.2021.
//  Copyright (c) 2021 marpies. All rights reserved.
//

import Foundation
import Swinject
import AppKit

protocol MailboxWorkerDelegate: AnyObject {
    func conversationsDidLoad(response: Conversations.LoadConversations.Response)
    func conversationsDidUpdate(response: Conversations.UpdateConversations.Response)
    func conversationDidUpdate(response: Conversations.UpdateConversation.Response)
    func conversationShouldLoad(response: Mailbox.LoadConversation.Response)
    func messagesDidLoad(response: Messages.LoadMessages.Response)
    func messagesDidUpdate(response: Messages.UpdateMessages.Response)
    func messageDidUpdate(response: Messages.UpdateMessage.Response)
    func mailboxDidUpdateWithoutChange()
    func loadDidFail(response: Mailbox.LoadError.Response)
    func mailboxSelectionDidUpdate(response: Mailbox.ItemsDidSelect.Response)
}

class MailboxWorker: MailboxManagingWorkerDelegate {
    
	private let resolver: Resolver
    private let usersManager: UsersManager
    
    private var mailboxWorker: MailboxManaging?
    
    private var toolbarActionObserver: NSObjectProtocol?
    
    private var activeUserId: String? {
        return self.usersManager.activeUser?.userId
    }
    
    /// The last loaded label. Nil if messages have not been loaded yet.
    var labelId: String?

	weak var delegate: MailboxWorkerDelegate?

	init(resolver: Resolver) {
		self.resolver = resolver
        self.usersManager = resolver.resolve(UsersManager.self)!
        
        self.addObservers()
	}

    func loadItems(request: Mailbox.LoadItems.Request) {
        guard let user = self.usersManager.activeUser else {
            fatalError("Unexpected application state.")
        }
        
        let labelId: String = request.labelId
        self.labelId = labelId
        
        self.loadItems(forLabel: labelId, userId: user.userId)
    }
    
    func updateItemStar(request: Mailbox.UpdateItemStar.Request) {
        guard let userId = self.activeUserId else { return }
        
        switch request.type {
        case .conversation:
            self.mailboxWorker?.updateConversationStar(id: request.id, isOn: request.isOn, userId: userId)
            
        case .message:
            self.mailboxWorker?.updateMessageStar(id: request.id, isOn: request.isOn, userId: userId)
        }
    }
    
    func processItemsSelection(request: Mailbox.ItemsDidSelect.Request) {
        // Single item selected, load conversation
        if request.ids.count == 1 {
            let conversationId: String
            
            switch request.type {
            case .conversation:
                conversationId = request.ids[0]
                
            case .message:
                guard let id = self.mailboxWorker?.getConversationId(forMessageId: request.ids[0]) else { return }
                
                conversationId = id
            }
            
            let response: Mailbox.LoadConversation.Response = Mailbox.LoadConversation.Response(id: conversationId)
            self.delegate?.conversationShouldLoad(response: response)
        }
        
        let response: Mailbox.ItemsDidSelect.Response = Mailbox.ItemsDidSelect.Response(isMultiSelection: request.ids.count > 1, type: request.type)
        self.delegate?.mailboxSelectionDidUpdate(response: response)
    }
    
    func refreshMailbox(eventsOnly: Bool) {
        self.mailboxWorker?.refreshMailbox(eventsOnly: eventsOnly)
    }
    
    //
    // MARK: - Conversations managing delegate
    //
    
    func cachedConversationsDidLoad(_ conversations: [Conversations.Conversation.Response]) {
        let response = Conversations.LoadConversations.Response(conversations: conversations, isServerResponse: false)
        self.delegate?.conversationsDidLoad(response: response)
    }
    
    func conversationsDidLoad(_ conversations: [Conversations.Conversation.Response]) {
        let response = Conversations.LoadConversations.Response(conversations: conversations, isServerResponse: true)
        self.delegate?.conversationsDidLoad(response: response)
    }
    
    func conversationsDidUpdate(response: Conversations.UpdateConversations.Response) {
        self.delegate?.conversationsDidUpdate(response: response)
    }
    
    func conversationsLoadDidFail(response: Conversations.LoadError.Response) {
        self.mailboxLoadDidFail(error: response.error)
    }
    
    func conversationDidUpdate(conversation: Conversations.Conversation.Response, index: Int) {
        let response: Conversations.UpdateConversation.Response = Conversations.UpdateConversation.Response(conversation: conversation, index: index)
        self.delegate?.conversationDidUpdate(response: response)
    }
    
    //
    // MARK: - Messages managing delegate
    //
    
    func cachedMessagesDidLoad(_ messages: [Messages.Message.Response]) {
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
        self.mailboxLoadDidFail(error: response.error)
    }
    
    func messageDidUpdate(message: Messages.Message.Response, index: Int) {
        let response: Messages.UpdateMessage.Response = Messages.UpdateMessage.Response(message: message, index: index)
        self.delegate?.messageDidUpdate(response: response)
    }
    
    //
    // MARK: - Mailbox managing delegate
    //
    
    func mailboxDidUpdateWithoutChange() {
        self.delegate?.mailboxDidUpdateWithoutChange()
    }
    
    func mailboxLoadDidFail(error: NSError) {
        let response: Mailbox.LoadError.Response = Mailbox.LoadError.Response(error: error)
        self.delegate?.loadDidFail(response: response)
    }
    
    //
    // MARK: - Private
    //
    
    private func loadItems(forLabel labelId: String, userId: String) {
        let item: MailboxSidebar.Item = MailboxSidebar.Item(id: labelId, title: nil)
        
        if self.mailboxWorker == nil || self.mailboxWorker!.userId != userId {
            self.mailboxWorker = self.resolver.resolve(MailboxManaging.self, argument: userId)
            self.mailboxWorker?.delegate = self
        }
        
        switch item {
        case .outbox, .draft:
            self.mailboxWorker?.loadMailbox(labelId: labelId, isMessages: true)
            
        default:
            self.mailboxWorker?.loadMailbox(labelId: labelId, isMessages: false)
        }
    }
    
    private func addObservers() {
        self.toolbarActionObserver = NotificationCenter.default.addObserver(forType: Main.Notifications.ToolbarAction.self, object: nil, queue: .main, using: { [weak self] notification in
            guard let id = notification?.itemId else { return }
            
            self?.processToolbarAction(id: id)
        })
    }
    
    private func processToolbarAction(id: NSToolbarItem.Identifier) {
        switch id {
        case .refreshMailbox:
            self.refreshMailbox(eventsOnly: true)
            
        default:
            return
        }
    }
    
}
