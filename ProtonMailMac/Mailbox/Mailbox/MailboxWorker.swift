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
    func conversationsDidRefresh(response: Conversations.RefreshConversations.Response)
    func conversationShouldLoad(response: Mailbox.LoadConversation.Response)
    func messagesDidLoad(response: Messages.LoadMessages.Response)
    func messagesDidUpdate(response: Messages.UpdateMessages.Response)
    func messageDidUpdate(response: Messages.UpdateMessage.Response)
    func messagesDidRefresh(response: Messages.RefreshMessages.Response)
    func mailboxDidUpdateWithoutChange()
    func loadDidFail(response: Mailbox.LoadError.Response)
    func mailboxSelectionDidUpdate(response: Mailbox.ItemsDidSelect.Response)
}

class MailboxWorker: MailboxManagingWorkerDelegate {
    
	private let resolver: Resolver
    private let usersManager: UsersManager
    
    /// List of ids for currently selected items (conversations or messages).
    private var selectedItemIds: [String]?
    private var selectedItemType: Mailbox.TableItem.Kind?
    
    private var mailboxWorker: MailboxManaging?
    
    private var toolbarActionObserver: NSObjectProtocol?
    private var toolbarMenuItemActionObserver: NSObjectProtocol?
    
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
        
        self.cancelSelection()
        
        self.loadItems(forLabel: labelId, userId: user.userId)
    }
    
    func updateItemStar(request: Mailbox.UpdateItemStar.Request) {
        guard let userId = self.activeUserId else { return }
        
        switch request.type {
        case .conversation:
            self.getMailboxWorker(userId: userId).updateConversationStar(id: request.id, isOn: request.isOn)
            
        case .message:
            self.getMailboxWorker(userId: userId).updateMessageStar(id: request.id, isOn: request.isOn)
        }
    }
    
    func processItemsSelection(request: Mailbox.ItemsDidSelect.Request) {
        guard let userId = self.activeUserId else { return }
        
        self.selectedItemIds = request.ids
        self.selectedItemType = request.type
        
        // Single item selected, load conversation
        if request.ids.count == 1 {
            let conversationId: String
            
            switch request.type {
            case .conversation:
                conversationId = request.ids[0]
                
            case .message:
                guard let id = self.getMailboxWorker(userId: userId).getConversationId(forMessageId: request.ids[0]) else { return }
                
                conversationId = id
            }
            
            let response: Mailbox.LoadConversation.Response = Mailbox.LoadConversation.Response(id: conversationId)
            self.delegate?.conversationShouldLoad(response: response)
        }
        
        // Provide selection info
        let selectionType: Mailbox.SelectionType
        
        switch request.type {
        case .conversation:
            selectionType = .conversations(request.ids)
        case .message:
            selectionType = .messages(request.ids)
        }
        
        let response: Mailbox.ItemsDidSelect.Response = Mailbox.ItemsDidSelect.Response(type: selectionType)
        self.delegate?.mailboxSelectionDidUpdate(response: response)
    }
    
    func refreshMailbox(eventsOnly: Bool) {
        guard let userId = self.activeUserId else { return }
        
        self.getMailboxWorker(userId: userId).refreshMailbox(eventsOnly: eventsOnly)
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
    
    func conversationDidUpdate(conversation: Conversations.Conversation.Response, index: Int) {
        let response: Conversations.UpdateConversation.Response = Conversations.UpdateConversation.Response(conversation: conversation, index: index)
        self.delegate?.conversationDidUpdate(response: response)
    }
    
    func conversationsDidRefresh(response: Conversations.RefreshConversations.Response) {
        self.delegate?.conversationsDidRefresh(response: response)
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
    
    func messageDidUpdate(message: Messages.Message.Response, index: Int) {
        let response: Messages.UpdateMessage.Response = Messages.UpdateMessage.Response(message: message, index: index)
        self.delegate?.messageDidUpdate(response: response)
    }
    
    func messagesDidRefresh(response: Messages.RefreshMessages.Response) {
        self.delegate?.messagesDidRefresh(response: response)
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
    
    func mailboxOperationsProcessingDidComplete() {
        self.refreshMailbox(eventsOnly: true)
    }
    
    //
    // MARK: - Private
    //
    
    private func loadItems(forLabel labelId: String, userId: String) {
        let item: MailboxSidebar.Item = MailboxSidebar.Item(id: labelId, title: nil)
        
        switch item {
        case .outbox, .draft:
            self.getMailboxWorker(userId: userId).loadMailbox(labelId: labelId, isMessages: true)
            
        default:
            self.getMailboxWorker(userId: userId).loadMailbox(labelId: labelId, isMessages: false)
        }
    }
    
    private func cancelSelection() {
        self.selectedItemType = nil
        self.selectedItemIds = nil
        
        let response: Mailbox.ItemsDidSelect.Response = Mailbox.ItemsDidSelect.Response(type: .none)
        self.delegate?.mailboxSelectionDidUpdate(response: response)
    }
    
    private func addObservers() {
        self.toolbarActionObserver = NotificationCenter.default.addObserver(forType: Main.Notifications.ToolbarAction.self, object: nil, queue: .main, using: { [weak self] notification in
            guard let id = notification?.itemId else { return }
            
            self?.processToolbarAction(id: id)
        })
        
        self.toolbarMenuItemActionObserver = NotificationCenter.default.addObserver(forType: Main.Notifications.ToolbarMenuItemAction.self, object: nil, queue: .main, using: { [weak self] notification in
            guard let action = notification?.action else { return }
            
            self?.processToolbarMenuItemAction(action)
        })
    }
    
    private func processToolbarAction(id: NSToolbarItem.Identifier) {
        switch id {
        case .refreshMailbox:
            self.refreshMailbox(eventsOnly: true)
            
        case .moveToTrash:
            self.processMoveToFolder(.trash)
            
        case .moveToArchive:
            self.processMoveToFolder(.archive)
            
        case .moveToSpam:
            self.processMoveToFolder(.spam)
            
        default:
            return
        }
    }
    
    private func processToolbarMenuItemAction(_ action: Main.ToolbarItem.MenuItem.Action) {
        switch action {
        case .moveToFolder(let folderId):
            self.processMoveToFolder(id: folderId)
            
        case .updateLabel(let labelId, let apply):
            self.processLabelUpdate(labelId: labelId, apply: apply)
        }
    }
    
    //
    // MARK: - Move to folder
    //
    
    private func processMoveToFolder(_ folder: MailboxSidebar.Item) {
        self.processMoveToFolder(id: folder.id)
    }
    
    private func processMoveToFolder(id: String) {
        guard let selectedItemIds = self.selectedItemIds,
              let selectedItemType = self.selectedItemType,
              let userId = self.activeUserId else { return }
        
        switch selectedItemType {
        case .conversation:
            self.getMailboxWorker(userId: userId).moveConversations(ids: selectedItemIds, toFolder: id)
        case .message:
            self.getMailboxWorker(userId: userId).moveMessages(ids: selectedItemIds, toFolder: id)
        }
    }
    
    //
    // MARK: - Labels update
    //
    
    private func processLabelUpdate(labelId: String, apply: Bool) {
        guard let selectedItemIds = self.selectedItemIds,
              let selectedItemType = self.selectedItemType,
              let userId = self.activeUserId else { return }
        
        switch selectedItemType {
        case .conversation:
            self.getMailboxWorker(userId: userId).updateConversationsLabel(ids: selectedItemIds, labelId: labelId, apply: apply)
        case .message:
            self.getMailboxWorker(userId: userId).updateMessagesLabel(ids: selectedItemIds, labelId: labelId, apply: apply)
        }
    }
    
    //
    // MARK: - Helpers
    //
    
    private func getMailboxWorker(userId: String) -> MailboxManaging {
        if self.mailboxWorker == nil || self.mailboxWorker!.userId != userId {
            self.mailboxWorker?.delegate = nil
            self.mailboxWorker?.cancelLoad()
            
            self.mailboxWorker = self.resolver.resolve(MailboxManaging.self, argument: userId)
            self.mailboxWorker?.delegate = self
        }
        
        return self.mailboxWorker!
    }
    
}
