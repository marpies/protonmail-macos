//
//  MailboxInteractor.swift
//  ProtonMailMac
//
//  Created by Marcel Piešťanský on 16.09.2021.
//  Copyright (c) 2021 marpies. All rights reserved.
//

import Foundation

protocol MailboxBusinessLogic {
    func loadItems(request: Mailbox.LoadItems.Request)
    func processErrorViewButtonTap()
    func updateItemStar(request: Mailbox.UpdateItemStar.Request)
    func processItemsSelection(request: Mailbox.ItemsDidSelect.Request)
    func processRefreshButtonTap()
}

protocol MailboxDataStore {
    
}

class MailboxInteractor: MailboxBusinessLogic, MailboxDataStore, MailboxWorkerDelegate {
    
    var worker: MailboxWorker?
    
    var presenter: MailboxPresentationLogic?
    
    //
    // MARK: - Load items
    //
    
    func loadItems(request: Mailbox.LoadItems.Request) {
        self.worker?.delegate = self
        self.worker?.loadItems(request: request)
    }
    
    //
    // MARK: - Process error view button tap
    //
    
    func processErrorViewButtonTap() {
        self.worker?.refreshMailbox()
    }
    
    //
    // MARK: - Star / unstar conversation
    //
    
    func updateItemStar(request: Mailbox.UpdateItemStar.Request) {
        self.worker?.updateItemStar(request: request)
    }
    
    //
    // MARK: - Process conversations selection
    //
    
    func processItemsSelection(request: Mailbox.ItemsDidSelect.Request) {
        self.worker?.processItemsSelection(request: request)
    }
    
    //
    // MARK: - Process refresh button tap
    //
    
    func processRefreshButtonTap() {
        self.worker?.refreshMailbox()
    }
    
    //
    // MARK: - Worker delegate
    //
    
    func conversationsDidLoad(response: Conversations.LoadConversations.Response) {
        self.presenter?.presentConversations(response: response)
    }
    
    func conversationsDidUpdate(response: Conversations.UpdateConversations.Response) {
        self.presenter?.presentConversationsUpdate(response: response)
    }
    
    func conversationDidUpdate(response: Conversations.UpdateConversation.Response) {
        self.presenter?.presentConversationUpdate(response: response)
    }
    
    func loadDidFail(response: Mailbox.LoadError.Response) {
        self.presenter?.presentLoadError(response: response)
    }
    
    func conversationShouldLoad(response: Mailbox.LoadConversation.Response) {
        self.presenter?.presentLoadConversation(response: response)
    }
    
    func messagesDidLoad(response: Messages.LoadMessages.Response) {
        self.presenter?.presentMessages(response: response)
    }
    
    func messageDidUpdate(response: Messages.UpdateMessage.Response) {
        self.presenter?.presentMessageUpdate(response: response)
    }
    
    func messagesDidUpdate(response: Messages.UpdateMessages.Response) {
        self.presenter?.presentMessagesUpdate(response: response)
    }
    
    func mailboxDidUpdateWithoutChange() {
        self.presenter?.presentItemsUpToDate()
    }
    
    func mailboxSelectionDidUpdate(response: Mailbox.ItemsDidSelect.Response) {
        self.presenter?.presentItemsSelection(response: response)
    }
    
}
