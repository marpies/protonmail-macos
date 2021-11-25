//
//  MailboxPresenter.swift
//  ProtonMailMac
//
//  Created by Marcel Piešťanský on 16.09.2021.
//  Copyright (c) 2021 marpies. All rights reserved.
//

import AppKit

protocol MailboxPresentationLogic {
    func presentConversations(response: Conversations.LoadConversations.Response)
    func presentConversationsUpdate(response: Conversations.UpdateConversations.Response)
    func presentConversationUpdate(response: Conversations.UpdateConversation.Response)
    func presentConversationsRefresh(response: Conversations.RefreshConversations.Response)
    func presentLoadConversation(response: Mailbox.LoadConversation.Response)
    func presentMessages(response: Messages.LoadMessages.Response)
    func presentMessagesUpdate(response: Messages.UpdateMessages.Response)
    func presentMessageUpdate(response: Messages.UpdateMessage.Response)
    func presentMessagesRefresh(response: Messages.RefreshMessages.Response)
    func presentLoadError(response: Mailbox.LoadError.Response)
    func presentItemsUpToDate()
    func presentItemsSelection(response: Mailbox.ItemsDidSelect.Response)
    func presentPageCountUpdate(response: Mailbox.PageCountUpdate.Response)
}

class MailboxPresenter: MailboxPresentationLogic, MessageTimePresenting, MessageLabelPresenting, MessageFolderPresenting,
                              MessageAttachmentIconPresenting, MessageStarPresenting {
    
    weak var viewController: MailboxDisplayLogic?
    
    let dateFormatter: DateFormatter
    
    init() {
        self.dateFormatter = DateFormatter()
        self.dateFormatter.locale = Locale.current
    }
    
    //
    // MARK: - Present conversations
    //
    
    func presentConversations(response: Conversations.LoadConversations.Response) {
        let items: [Mailbox.TableItem.ViewModel] = response.conversations.map { self.getItem(response: $0) }
        let viewModel = Mailbox.LoadItems.ViewModel(items: items, removeErrorView: response.isServerResponse)
        self.viewController?.displayItems(viewModel: viewModel)
    }
    
    //
    // MARK: - Present conversations update
    //
    
    func presentConversationsUpdate(response: Conversations.UpdateConversations.Response) {
        let items: [Mailbox.TableItem.ViewModel] = response.conversations.map { self.getItem(response: $0) }
        let viewModel = Mailbox.UpdateItems.ViewModel(items: items, removeSet: response.removeSet, insertSet: response.insertSet, updateSet: response.updateSet)
        self.viewController?.displayItemsUpdate(viewModel: viewModel)
    }
    
    //
    // MARK: - Present conversation update
    //
    
    func presentConversationUpdate(response: Conversations.UpdateConversation.Response) {
        let item: Mailbox.TableItem.ViewModel = self.getItem(response: response.conversation)
        let viewModel = Mailbox.UpdateItem.ViewModel(item: item, index: response.index)
        self.viewController?.displayItemUpdate(viewModel: viewModel)
    }
    
    //
    // MARK: - Present conversations refresh
    //
    
    func presentConversationsRefresh(response: Conversations.RefreshConversations.Response) {
        let items: [(Mailbox.TableItem.ViewModel, Int)] = response.conversations.map { pair in
            let item: Mailbox.TableItem.ViewModel = self.getItem(response: pair.0)
            let index: Int = pair.1
            return (item, index)
        }
        let viewModel = Mailbox.RefreshItems.ViewModel(items: items, indexSet: response.indexSet)
        self.viewController?.displayItemsRefresh(viewModel: viewModel)
    }
    
    //
    // MARK: - Present load error
    //
    
    func presentLoadError(response: Mailbox.LoadError.Response) {
        let message: String
        
        if response.error.isInternetError() {
            message = NSLocalizedString("messagesLoadInternetErrorMessage", comment: "")
        } else {
            message = NSLocalizedString("messagesLoadGenericErrorMessage", comment: "")
        }
        
        let button: String = NSLocalizedString("messagesRetryLoadButton", comment: "")
        
        let viewModel = Mailbox.LoadError.ViewModel(message: message, button: button)
        self.viewController?.displayMailboxError(viewModel: viewModel)
    }
    
    //
    // MARK: - Present conversations up to date
    //
    
    func presentItemsUpToDate() {
        self.viewController?.displayMailboxUpToDate()
    }
    
    //
    // MARK: - Present items selection
    //
    
    func presentItemsSelection(response: Mailbox.ItemsDidSelect.Response) {
        let viewModel = Mailbox.ItemsDidSelect.ViewModel(type: response.type)
        self.viewController?.displayItemsSelection(viewModel: viewModel)
    }
    
    //
    // MARK: - Present load conversation
    //
    
    func presentLoadConversation(response: Mailbox.LoadConversation.Response) {
        let viewModel = Mailbox.LoadConversation.ViewModel(id: response.id)
        self.viewController?.displayLoadConversation(viewModel: viewModel)
    }
    
    //
    // MARK: - Present messages
    //
    
    func presentMessages(response: Messages.LoadMessages.Response) {
        let items: [Mailbox.TableItem.ViewModel] = response.messages.map { self.getItem(response: $0) }
        let viewModel = Mailbox.LoadItems.ViewModel(items: items, removeErrorView: response.isServerResponse)
        self.viewController?.displayItems(viewModel: viewModel)
    }
    
    //
    // MARK: - Present messages update
    //
    
    func presentMessagesUpdate(response: Messages.UpdateMessages.Response) {
        let items: [Mailbox.TableItem.ViewModel] = response.messages.map { self.getItem(response: $0) }
        let viewModel = Mailbox.UpdateItems.ViewModel(items: items, removeSet: response.removeSet, insertSet: response.insertSet, updateSet: response.updateSet)
        self.viewController?.displayItemsUpdate(viewModel: viewModel)
    }
    
    //
    // MARK: - Present message update
    //
    
    func presentMessageUpdate(response: Messages.UpdateMessage.Response) {
        let item: Mailbox.TableItem.ViewModel = self.getItem(response: response.message)
        let viewModel = Mailbox.UpdateItem.ViewModel(item: item, index: response.index)
        self.viewController?.displayItemUpdate(viewModel: viewModel)
    }
    
    //
    // MARK: - Present messages refresh
    //
    
    func presentMessagesRefresh(response: Messages.RefreshMessages.Response) {
        let items: [(Mailbox.TableItem.ViewModel, Int)] = response.messages.map { pair in
            let item: Mailbox.TableItem.ViewModel = self.getItem(response: pair.0)
            let index: Int = pair.1
            return (item, index)
        }
        let viewModel = Mailbox.RefreshItems.ViewModel(items: items, indexSet: response.indexSet)
        self.viewController?.displayItemsRefresh(viewModel: viewModel)
    }
    
    //
    // MARK: - Present page count update
    //
    
    func presentPageCountUpdate(response: Mailbox.PageCountUpdate.Response) {
        var pages: [Mailbox.Page.ViewModel] = []
        
        // Show previous page number if we are on page 2 or further
        let isOnFirstPage: Bool = response.currentPage <= 1
        if !isOnFirstPage {
            let prevPage: Int = response.currentPage - 1
            pages.append(self.getPageButton(type: .specific(page: String(prevPage))))
        }
        
        // Current page
        pages.append(self.getPageButton(type: .specific(page: String(response.currentPage)), isCurrentPage: true))
        
        // Show next page number if we are not on the last page
        let isOnLastPage: Bool = response.currentPage >= response.numPages
        if !isOnLastPage {
            let nextPage: Int = response.currentPage + 1
            pages.append(self.getPageButton(type: .specific(page: String(nextPage))))
        }
        
        let selectedIndex: Int = pages.firstIndex(where: { $0.title == String(response.currentPage) } )!
        
        let firstPageIcon: Mailbox.Page.ViewModel = self.getPageButton(type: .first)
        let previousPageIcon: Mailbox.Page.ViewModel = self.getPageButton(type: .previous)
        let nextPageIcon: Mailbox.Page.ViewModel = self.getPageButton(type: .next)
        let lastPageIcon: Mailbox.Page.ViewModel = self.getPageButton(type: .last)
        
        let viewModel = Mailbox.PageCountUpdate.ViewModel(pages: pages, selectedIndex: selectedIndex, firstPageIcon: firstPageIcon, previousPageIcon: previousPageIcon, lastPageIcon: lastPageIcon, nextPageIcon: nextPageIcon, previousButtonsEnabled: !isOnFirstPage, nextButtonsEnabled: !isOnLastPage)
        self.viewController?.displayPageCountUpdate(viewModel: viewModel)
    }
    
    //
    // MARK: - Private
    //
    
    private func getItem(response: Conversations.Conversation.Response) -> Mailbox.TableItem.ViewModel {
        let title: String = response.senderNames.joined(separator: ", ")
        let time: String = self.getMessageTime(response: response.time)
        let folders: [Messages.Folder.ViewModel]? = response.folders?.map { self.getFolder(response: $0) }
        let labels: [Messages.Label.ViewModel]? = response.labels?.map { self.getLabel(response: $0) }
        let starIcon: Messages.Star.ViewModel = self.getStarIcon(isSelected: response.isStarred)
        let attachmentIcon: Messages.Attachment.ViewModel? = self.getAttachmentIcon(numAttachments: response.numAttachments)
        let subject: String = self.getSubject(response.subject, numMessages: response.numMessages)
        return Mailbox.TableItem.ViewModel(type: .conversation, id: response.id, title: title, subtitle: subject, time: time, isRead: response.isRead, starIcon: starIcon, folders: folders, labels: labels, attachmentIcon: attachmentIcon)
    }
    
    private func getItem(response: Messages.Message.Response) -> Mailbox.TableItem.ViewModel {
        let title: String = self.getTitle(response.sender)
        let time: String = self.getMessageTime(response: response.time)
        let folders: [Messages.Folder.ViewModel]? = response.folders?.map { self.getFolder(response: $0) }
        let labels: [Messages.Label.ViewModel]? = response.labels?.map { self.getLabel(response: $0) }
        let starIcon: Messages.Star.ViewModel = self.getStarIcon(isSelected: response.isStarred)
        let attachmentIcon: Messages.Attachment.ViewModel? = self.getAttachmentIcon(numAttachments: response.numAttachments)
        return Mailbox.TableItem.ViewModel(type: .message, id: response.id, title: title, subtitle: response.subject, time: time, isRead: response.isRead, starIcon: starIcon, folders: folders, labels: labels, attachmentIcon: attachmentIcon)
    }
    
    private func getTitle(_ sender: Messages.Message.ContactInfo.Response) -> String {
        if !sender.name.isEmpty {
            return sender.name
        }
        return sender.email
    }
    
    private func getSubject(_ subject: String, numMessages: Int) -> String {
        if numMessages > 1 {
            return "[\(numMessages)] \(subject)"
        }
        return subject
    }
    
    private func getPageButton(type: Mailbox.Page, isCurrentPage: Bool = false) -> Mailbox.Page.ViewModel {
        let tooltip: String = self.getPageTooltip(type: type, isCurrentPage: isCurrentPage)
        
        switch type {
        case .first:
            return Mailbox.Page.ViewModel(title: nil, image: NSImage.universal(name: "chevron.left.2"), tooltip: tooltip)
        case .previous:
            return Mailbox.Page.ViewModel(title: nil, image: NSImage.universal(name: "chevron.left"), tooltip: tooltip)
        case .next:
            return Mailbox.Page.ViewModel(title: nil, image: NSImage.universal(name: "chevron.right"), tooltip: tooltip)
        case .last:
            return Mailbox.Page.ViewModel(title: nil, image: NSImage.universal(name: "chevron.right.2"), tooltip: tooltip)
        case .specific(let page):
            return Mailbox.Page.ViewModel(title: page, image: nil, tooltip: tooltip)
        }
    }
    
    private func getPageTooltip(type: Mailbox.Page, isCurrentPage: Bool) -> String {
        if isCurrentPage, case .specific(let page) = type {
            let format: String = NSLocalizedString("pagingCurrentPageTooltip", comment: "")
            return String(format: format, page)
        }
        
        switch type {
        case .first:
            return NSLocalizedString("pagingGoToFirstPageTooltip", comment: "")
        case .previous:
            return NSLocalizedString("pagingGoToPreviousPageTooltip", comment: "")
        case .next:
            return NSLocalizedString("pagingGoToNextPageTooltip", comment: "")
        case .last:
            return NSLocalizedString("pagingGoToLastPageTooltip", comment: "")
        case .specific(let page):
            let format: String = NSLocalizedString("pagingGoToPageTooltip", comment: "")
            return String(format: format, page)
        }
    }
    
}
