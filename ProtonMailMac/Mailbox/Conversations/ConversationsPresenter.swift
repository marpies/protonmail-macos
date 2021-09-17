//
//  ConversationsPresenter.swift
//  ProtonMailMac
//
//  Created by Marcel Piešťanský on 16.09.2021.
//  Copyright (c) 2021 marpies. All rights reserved.
//

import AppKit

protocol ConversationsPresentationLogic {
    func presentConversations(response: Conversations.LoadConversations.Response)
    func presentConversationsUpdate(response: Conversations.UpdateConversations.Response)
    func presentConversationUpdate(response: Conversations.UpdateConversation.Response)
    func presentConversationsError(response: Conversations.LoadError.Response)
    func presentConversationsUpToDate()
}

class ConversationsPresenter: ConversationsPresentationLogic, MessageTimePresenting, MessageLabelPresenting, MessageFolderPresenting,
                              MessageAttachmentIconPresenting, MessageStarPresenting {
    
    weak var viewController: ConversationsDisplayLogic?
    
    let dateFormatter: DateFormatter
    
    init() {
        self.dateFormatter = DateFormatter()
        self.dateFormatter.locale = Locale.current
    }
    
    //
    // MARK: - Present conversations
    //
    
    func presentConversations(response: Conversations.LoadConversations.Response) {
        let conversations: [Conversations.Conversation.ViewModel] = response.conversations.map { self.getConversation(response: $0) }
        let viewModel = Conversations.LoadConversations.ViewModel(conversations: conversations, removeErrorView: response.isServerResponse)
        self.viewController?.displayConversations(viewModel: viewModel)
    }
    
    //
    // MARK: - Present conversations update
    //
    
    func presentConversationsUpdate(response: Conversations.UpdateConversations.Response) {
        let conversations: [Conversations.Conversation.ViewModel] = response.conversations.map { self.getConversation(response: $0) }
        let viewModel = Conversations.UpdateConversations.ViewModel(conversations: conversations, removeSet: response.removeSet, insertSet: response.insertSet, updateSet: response.updateSet)
        self.viewController?.displayConversationsUpdate(viewModel: viewModel)
    }
    
    //
    // MARK: - Present conversation update
    //
    
    func presentConversationUpdate(response: Conversations.UpdateConversation.Response) {
        let conversation: Conversations.Conversation.ViewModel = self.getConversation(response: response.conversation)
        let viewModel = Conversations.UpdateConversation.ViewModel(conversation: conversation, index: response.index)
        self.viewController?.displayConversationUpdate(viewModel: viewModel)
    }
    
    //
    // MARK: - Present messages error
    //
    
    func presentConversationsError(response: Conversations.LoadError.Response) {
        let message: String
        
        if response.error.isInternetError() {
            message = NSLocalizedString("messagesLoadInternetErrorMessage", comment: "")
        } else {
            message = NSLocalizedString("messagesLoadGenericErrorMessage", comment: "")
        }
        
        let button: String = NSLocalizedString("messagesRetryLoadButton", comment: "")
        
        let viewModel = Conversations.LoadError.ViewModel(message: message, button: button)
        self.viewController?.displayConversationsError(viewModel: viewModel)
    }
    
    //
    // MARK: - Present conversations up to date
    //
    
    func presentConversationsUpToDate() {
        self.viewController?.displayConversationsUpToDate()
    }
    
    //
    // MARK: - Private
    //
    
    private func getConversation(response: Conversations.Conversation.Response) -> Conversations.Conversation.ViewModel {
        let title: String = self.getTitle(senders: response.senderNames, numMessages: response.numMessages)
        let time: String = self.getMessageTime(response: response.time)
        let folders: [Messages.Folder.ViewModel]? = response.folders?.map { self.getFolder(response: $0) }
        let labels: [Messages.Label.ViewModel]? = response.labels?.map { self.getLabel(response: $0) }
        let starIcon: Messages.Star.ViewModel = self.getStarIcon(isSelected: response.isStarred)
        var attachmentIcon: Messages.Attachment.ViewModel? = nil
        if response.numAttachments > 0 {
            let format: String = NSLocalizedString("num_attachments", comment: "")
            let title: String = String.localizedStringWithFormat(format, response.numAttachments)
            attachmentIcon = Messages.Attachment.ViewModel(icon: "paperclip", title: title)
        }
        return Conversations.Conversation.ViewModel(id: response.id, title: title, subtitle: response.subject, time: time, isRead: response.isRead, starIcon: starIcon, folders: folders, labels: labels, attachmentIcon: attachmentIcon)
    }
    
    private func getTitle(senders: [String], numMessages: Int) -> String {
        let senders: String = senders.joined(separator: ", ")
        if numMessages > 1 {
            return "[\(numMessages)] \(senders)"
        }
        return senders
    }
    
}
