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
    func presentLoadError(response: Conversations.LoadError.Response)
    func presentLoadConversation(response: Conversations.LoadConversation.Response)
    func presentMessages(response: Messages.LoadMessages.Response)
    func presentMessagesUpdate(response: Messages.UpdateMessages.Response)
    func presentMessageUpdate(response: Messages.UpdateMessage.Response)
    func presentItemsUpToDate()
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
        let items: [Conversations.TableItem.ViewModel] = response.conversations.map { self.getItem(response: $0) }
        let viewModel = Conversations.LoadItems.ViewModel(items: items, removeErrorView: response.isServerResponse)
        self.viewController?.displayItems(viewModel: viewModel)
    }
    
    //
    // MARK: - Present conversations update
    //
    
    func presentConversationsUpdate(response: Conversations.UpdateConversations.Response) {
        let items: [Conversations.TableItem.ViewModel] = response.conversations.map { self.getItem(response: $0) }
        let viewModel = Conversations.UpdateItems.ViewModel(items: items, removeSet: response.removeSet, insertSet: response.insertSet, updateSet: response.updateSet)
        self.viewController?.displayItemsUpdate(viewModel: viewModel)
    }
    
    //
    // MARK: - Present conversation update
    //
    
    func presentConversationUpdate(response: Conversations.UpdateConversation.Response) {
        let item: Conversations.TableItem.ViewModel = self.getItem(response: response.conversation)
        let viewModel = Conversations.UpdateItem.ViewModel(item: item, index: response.index)
        self.viewController?.displayItemUpdate(viewModel: viewModel)
    }
    
    //
    // MARK: - Present load error
    //
    
    func presentLoadError(response: Conversations.LoadError.Response) {
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
    
    func presentItemsUpToDate() {
        self.viewController?.displayConversationsUpToDate()
    }
    
    //
    // MARK: - Present load conversation
    //
    
    func presentLoadConversation(response: Conversations.LoadConversation.Response) {
        let viewModel = Conversations.LoadConversation.ViewModel(id: response.id)
        self.viewController?.displayLoadConversation(viewModel: viewModel)
    }
    
    //
    // MARK: - Present messages
    //
    
    func presentMessages(response: Messages.LoadMessages.Response) {
        let items: [Conversations.TableItem.ViewModel] = response.messages.map { self.getItem(response: $0) }
        let viewModel = Conversations.LoadItems.ViewModel(items: items, removeErrorView: response.isServerResponse)
        self.viewController?.displayItems(viewModel: viewModel)
    }
    
    //
    // MARK: - Present messages update
    //
    
    func presentMessagesUpdate(response: Messages.UpdateMessages.Response) {
        let items: [Conversations.TableItem.ViewModel] = response.messages.map { self.getItem(response: $0) }
        let viewModel = Conversations.UpdateItems.ViewModel(items: items, removeSet: response.removeSet, insertSet: response.insertSet, updateSet: response.updateSet)
        self.viewController?.displayItemsUpdate(viewModel: viewModel)
    }
    
    //
    // MARK: - Present message update
    //
    
    func presentMessageUpdate(response: Messages.UpdateMessage.Response) {
        let item: Conversations.TableItem.ViewModel = self.getItem(response: response.message)
        let viewModel = Conversations.UpdateItem.ViewModel(item: item, index: response.index)
        self.viewController?.displayItemUpdate(viewModel: viewModel)
    }
    
    //
    // MARK: - Private
    //
    
    private func getItem(response: Conversations.Conversation.Response) -> Conversations.TableItem.ViewModel {
        let title: String = self.getTitle(senders: response.senderNames, numMessages: response.numMessages)
        let time: String = self.getMessageTime(response: response.time)
        let folders: [Messages.Folder.ViewModel]? = response.folders?.map { self.getFolder(response: $0) }
        let labels: [Messages.Label.ViewModel]? = response.labels?.map { self.getLabel(response: $0) }
        let starIcon: Messages.Star.ViewModel = self.getStarIcon(isSelected: response.isStarred)
        let attachmentIcon: Messages.Attachment.ViewModel? = self.getAttachmentIcon(numAttachments: response.numAttachments)
        return Conversations.TableItem.ViewModel(type: .conversation, id: response.id, title: title, subtitle: response.subject, time: time, isRead: response.isRead, starIcon: starIcon, folders: folders, labels: labels, attachmentIcon: attachmentIcon)
    }
    
    private func getItem(response: Messages.Message.Response) -> Conversations.TableItem.ViewModel {
        let title: String = response.senderName
        let time: String = self.getMessageTime(response: response.time)
        let folders: [Messages.Folder.ViewModel]? = response.folders?.map { self.getFolder(response: $0) }
        let labels: [Messages.Label.ViewModel]? = response.labels?.map { self.getLabel(response: $0) }
        let starIcon: Messages.Star.ViewModel = self.getStarIcon(isSelected: response.isStarred)
        let attachmentIcon: Messages.Attachment.ViewModel? = self.getAttachmentIcon(numAttachments: response.numAttachments)
        return Conversations.TableItem.ViewModel(type: .message, id: response.id, title: title, subtitle: response.subject, time: time, isRead: response.isRead, starIcon: starIcon, folders: folders, labels: labels, attachmentIcon: attachmentIcon)
    }
    
    private func getTitle(senders: [String], numMessages: Int) -> String {
        let senders: String = senders.joined(separator: ", ")
        if numMessages > 1 {
            return "[\(numMessages)] \(senders)"
        }
        return senders
    }
    
}
