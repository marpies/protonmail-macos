//
//  ConversationsInteractor.swift
//  ProtonMailMac
//
//  Created by Marcel Piešťanský on 16.09.2021.
//  Copyright (c) 2021 marpies. All rights reserved.
//

import Foundation

protocol ConversationsBusinessLogic {
    func loadConversations(request: Conversations.LoadConversations.Request)
    func processErrorViewButtonTap()
    func starConversation(request: Conversations.StarConversation.Request)
    func unstarConversation(request: Conversations.UnstarConversation.Request)
    func processConversationsSelection(request: Conversations.ConversationsDidSelect.Request)
    func processRefreshButtonTap()
}

protocol ConversationsDataStore {
    
}

class ConversationsInteractor: ConversationsBusinessLogic, ConversationsDataStore, ConversationsWorkerDelegate {
    
    var worker: ConversationsWorker?
    
    var presenter: ConversationsPresentationLogic?
    
    //
    // MARK: - Load conversations
    //
    
    func loadConversations(request: Conversations.LoadConversations.Request) {
        self.worker?.delegate = self
        self.worker?.loadConversations(request: request)
    }
    
    //
    // MARK: - Process error view button tap
    //
    
    func processErrorViewButtonTap() {
        self.worker?.reloadConversations()
    }
    
    //
    // MARK: - Star / unstar conversation
    //
    
    func starConversation(request: Conversations.StarConversation.Request) {
        self.worker?.starConversation(request: request)
    }
    
    func unstarConversation(request: Conversations.UnstarConversation.Request) {
        self.worker?.unstarConversation(request: request)
    }
    
    //
    // MARK: - Process conversations selection
    //
    
    func processConversationsSelection(request: Conversations.ConversationsDidSelect.Request) {
        self.worker?.processConversationsSelection(request: request)
    }
    
    //
    // MARK: - Process refresh button tap
    //
    
    func processRefreshButtonTap() {
        self.worker?.reloadConversations()
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
    
    func conversationsLoadDidFail(response: Conversations.LoadError.Response) {
        self.presenter?.presentConversationsError(response: response)
    }
    
    func conversationsDidUpdateWithoutChange() {
        self.presenter?.presentConversationsUpToDate()
    }
    
}
