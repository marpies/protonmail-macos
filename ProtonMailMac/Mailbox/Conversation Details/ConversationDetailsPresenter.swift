//
//  ConversationDetailsPresenter.swift
//  ProtonMailMac
//
//  Created by Marcel Piešťanský on 17.09.2021.
//  Copyright (c) 2021 marpies. All rights reserved.
//

import AppKit

protocol ConversationDetailsPresentationLogic {
    func presentOverview(response: ConversationDetails.Overview.Response)
    func presentConversationLoadDidBegin()
    func presentConversation(response: ConversationDetails.Load.Response)
    func presentLoadError(response: ConversationDetails.LoadError.Response)
    func presentMessageUpdate(response: ConversationDetails.UpdateMessage.Response)
    func presentConversationUpdate(response: ConversationDetails.UpdateConversation.Response)
    func presentMessageContentLoading(response: ConversationDetails.MessageContentLoadDidBegin.Response)
    func presentMessageContentLoaded(response: ConversationDetails.MessageContentLoaded.Response)
    func presentMessageContentCollapsed(response: ConversationDetails.MessageContentCollapsed.Response)
    func presentMessageContentError(response: ConversationDetails.MessageContentError.Response)
    func presentRemoteContentBox(response: ConversationDetails.DisplayRemoteContentBox.Response)
    func removeRemoteContentBox(response: ConversationDetails.RemoveRemoteContentBox.Response)
}

class ConversationDetailsPresenter: ConversationDetailsPresentationLogic, MessageLabelPresenting, MessageFolderPresenting, MessageTimePresenting,
                                    MessageStarPresenting, MessageAttachmentIconPresenting {
    
	weak var viewController: ConversationDetailsDisplayLogic?
    
    let dateFormatter: DateFormatter
    
    init() {
        self.dateFormatter = DateFormatter()
        self.dateFormatter.locale = Locale.current
    }
    
    //
    // MARK: - Present overview
    //
    
    func presentOverview(response: ConversationDetails.Overview.Response) {
        let title: String
        let icon: String
        var isFolder: Bool = true
        var isConversation: Bool = true
        let color: NSColor = response.color ?? .labelColor
        
        switch response.label {
        case .draft:
            title = NSLocalizedString("mailboxLabelDrafts", comment: "")
            icon = "note.text"
            isConversation = false
        case .inbox:
            title = NSLocalizedString("mailboxLabelInbox", comment: "")
            icon = "tray"
        case .outbox:
            title = NSLocalizedString("mailboxLabelSent", comment: "")
            icon = "paperplane"
            isConversation = false
        case .spam:
            title = NSLocalizedString("mailboxLabelSpam", comment: "")
            icon = "flame"
        case .archive:
            title = NSLocalizedString("mailboxLabelArchive", comment: "")
            icon = "archivebox"
        case .trash:
            title = NSLocalizedString("mailboxLabelTrash", comment: "")
            icon = "trash"
        case .allMail:
            title = NSLocalizedString("mailboxLabelAllMail", comment: "")
            icon = "mail.stack"
        case .starred:
            title = NSLocalizedString("mailboxLabelStarred", comment: "")
            icon = "star"
        case .custom(_, let name, let folder):
            title = name
            isFolder = folder
            icon = folder ? "folder" : "tag"
        }
        
        let countFormat: String
        let messageFormat: String
        
        if isFolder {
            if isConversation {
                countFormat = NSLocalizedString("has_num_conversations", comment: "")
            } else {
                countFormat = NSLocalizedString("has_num_messages", comment: "")
            }
            messageFormat = NSLocalizedString("totalCountInFolderMessage", comment: "")
        } else {
            countFormat = NSLocalizedString("has_num_conversations", comment: "")
            messageFormat = NSLocalizedString("totalCountWithLabelMessage", comment: "")
        }
        
        let countMessage: String = String.localizedStringWithFormat(countFormat, response.numItems)
        let message: String = String.localizedStringWithFormat(messageFormat, countMessage)
        
        let viewModel = ConversationDetails.Overview.ViewModel(title: title, message: message, icon: icon, color: color)
        self.viewController?.displayOverview(viewModel: viewModel)
    }
    
    //
    // MARK: - Present conversation load did begin
    //
    
    func presentConversationLoadDidBegin() {
        self.viewController?.displayConversationLoadDidBegin()
    }

    //
    // MARK: - Present conversation details
    //
    
    func presentConversation(response: ConversationDetails.Load.Response) {
        let conversation: ConversationDetails.Conversation.ViewModel = self.getConversation(response: response.conversation)
        let viewModel: ConversationDetails.Load.ViewModel = ConversationDetails.Load.ViewModel(conversation: conversation)
        self.viewController?.displayConversation(viewModel: viewModel)
    }
    
    //
    // MARK: - Present load error
    //
    
    func presentLoadError(response: ConversationDetails.LoadError.Response) {
        let button: String = NSLocalizedString("messagesRetryLoadButton", comment: "")
        let message: String
        
        if response.hasCachedMessages {
            message = NSLocalizedString("conversationLoadErrorPotentiallyOutdatedMessage", comment: "")
        } else {
            message = NSLocalizedString("conversationLoadErrorMessage", comment: "")
        }
        
        let conversation: ConversationDetails.Conversation.ViewModel = self.getConversation(response: response.conversation)
        let viewModel = ConversationDetails.LoadError.ViewModel(conversation: conversation, message: message, button: button)
        self.viewController?.displayLoadError(viewModel: viewModel)
    }
    
    //
    // MARK: - Present message update
    //
    
    func presentMessageUpdate(response: ConversationDetails.UpdateMessage.Response) {
        let message: Messages.Message.ViewModel = self.getMessage(response: response.message)
        let viewModel = ConversationDetails.UpdateMessage.ViewModel(message: message)
        self.viewController?.displayMessageUpdate(viewModel: viewModel)
    }
    
    //
    // MARK: - Present conversation update
    //
    
    func presentConversationUpdate(response: ConversationDetails.UpdateConversation.Response) {
        let conversation: ConversationDetails.Conversation.ViewModel = self.getConversation(response: response.conversation)
        let viewModel = ConversationDetails.UpdateConversation.ViewModel(conversation: conversation)
        self.viewController?.displayConversationUpdate(viewModel: viewModel)
    }
    
    //
    // MARK: - Present message content loading
    //
    
    func presentMessageContentLoading(response: ConversationDetails.MessageContentLoadDidBegin.Response) {
        let viewModel = ConversationDetails.MessageContentLoadDidBegin.ViewModel(id: response.id)
        self.viewController?.displayMessageContentLoading(viewModel: viewModel)
    }
    
    //
    // MARK: - Present message content loaded
    //
    
    func presentMessageContentLoaded(response: ConversationDetails.MessageContentLoaded.Response) {
        let contents: Messages.Message.Contents.ViewModel = Messages.Message.Contents.ViewModel(contents: response.contents.contents, loader: response.contents.loader)
        let viewModel = ConversationDetails.MessageContentLoaded.ViewModel(messageId: response.messageId, contents: contents)
        self.viewController?.displayMessageContentLoaded(viewModel: viewModel)
    }
    
    //
    // MARK: - Present message content collapsed
    //
    
    func presentMessageContentCollapsed(response: ConversationDetails.MessageContentCollapsed.Response) {
        let viewModel = ConversationDetails.MessageContentCollapsed.ViewModel(messageId: response.messageId)
        self.viewController?.displayMessageContentCollapsed(viewModel: viewModel)
    }
    
    //
    // MARK: - Present message content error
    //
    
    func presentMessageContentError(response: ConversationDetails.MessageContentError.Response) {
        let message: String
        let button: String = NSLocalizedString("messageBodyRetryLoadButton", comment: "")
        
        switch response.type {
        case .load:
            message = NSLocalizedString("messageBodyLoadErrorMessage", comment: "")
        case .decryption:
            message = NSLocalizedString("messageBodyDecryptErrorMessage", comment: "")
        }
        
        let viewModel = ConversationDetails.MessageContentError.ViewModel(messageId: response.messageId, errorMessage: message, button: button)
        self.viewController?.displayMessageContentError(viewModel: viewModel)
    }
    
    //
    // MARK: - Present remote content box
    //
    
    func presentRemoteContentBox(response: ConversationDetails.DisplayRemoteContentBox.Response) {
        let message: String = NSLocalizedString("messageHasRemoteContentBoxMessage", comment: "")
        let button: String = NSLocalizedString("messageLoadRemoteContentButton", comment: "")
        let box: Messages.Message.RemoteContentBox.ViewModel = Messages.Message.RemoteContentBox.ViewModel(message: message, button: button)
        let viewModel = ConversationDetails.DisplayRemoteContentBox.ViewModel(messageId: response.messageId, box: box)
        self.viewController?.displayRemoteContentBox(viewModel: viewModel)
    }
    
    //
    // MARK: - Remove remote content box
    //
    
    func removeRemoteContentBox(response: ConversationDetails.RemoveRemoteContentBox.Response) {
        let viewModel = ConversationDetails.RemoveRemoteContentBox.ViewModel(messageId: response.messageId)
        self.viewController?.removeRemoteContentBox(viewModel: viewModel)
    }
    
    //
    // MARK: - Private
    //
    
    private func getConversation(response: ConversationDetails.Conversation.Response) -> ConversationDetails.Conversation.ViewModel {
        let conversation: Conversations.Conversation.Response = response.conversation
        let starIcon: Messages.Star.ViewModel = self.getStarIcon(isSelected: conversation.isStarred)
        let labels: [Messages.Label.ViewModel]? = conversation.labels?.map { self.getLabel(response: $0) }
        let messages: [Messages.Message.ViewModel] = response.messages.map { self.getMessage(response: $0) }
        return ConversationDetails.Conversation.ViewModel(title: conversation.subject, starIcon: starIcon, labels: labels, messages: messages)
    }
    
    private func getMessage(response: Messages.Message.Response) -> Messages.Message.ViewModel {
        let sender: Messages.Message.Header.ContactsGroup.Item.ViewModel = self.getContactGroupItem(response.sender)
        let labels: [Messages.Label.ViewModel]? = response.labels?.map { self.getLabel(response: $0) }
        let folders: [Messages.Folder.ViewModel] = response.folders?.map { self.getFolder(response: $0) } ?? []
        let date: String = self.getMessageTime(response: response.time)
        let starIcon: Messages.Star.ViewModel = self.getStarIcon(isSelected: response.isStarred)
        let attachmentIcon: Messages.Attachment.ViewModel? = self.getAttachmentIcon(numAttachments: response.numAttachments)
        var repliedIcon: Messages.Icon.ViewModel?
        if response.isRepliedTo {
            let tooltip: String = NSLocalizedString("messageDetailRepliedToIconTooltip", comment: "")
            repliedIcon = Messages.Icon.ViewModel(icon: "arrowshape.turn.up.left", color: .secondaryLabelColor, tooltip: tooltip)
        }
        var draftLabel: Messages.Label.ViewModel?
        if response.isDraft {
            let title: String = NSLocalizedString("messageLabelDraft", comment: "")
            draftLabel = Messages.Label.ViewModel(id: "", title: title, color: .systemGreen)
        }
        
        let sentTo: Messages.Message.Header.ContactsGroup.ViewModel? = self.getContactsGroup(title: NSLocalizedString("messageSentToTitle", comment: ""), response: response.sentTo)
        let copyTo: Messages.Message.Header.ContactsGroup.ViewModel? = self.getContactsGroup(title: NSLocalizedString("messageCopyToTitle", comment: ""), response: response.copyTo)
        let blindCopyTo: Messages.Message.Header.ContactsGroup.ViewModel? = self.getContactsGroup(title: NSLocalizedString("messageBlindCopyToTitle", comment: ""), response: response.blindCopyTo)
        
        let header: Messages.Message.Header.ViewModel = Messages.Message.Header.ViewModel(sender: sender, labels: labels, folders: folders, date: date, starIcon: starIcon, isRead: response.isRead, draftLabel: draftLabel, repliedIcon: repliedIcon, attachmentIcon: attachmentIcon, sentTo: sentTo, copyTo: copyTo, blindCopyTo: blindCopyTo)
        return Messages.Message.ViewModel(id: response.id, header: header)
    }
    
    private func getTitle(_ sender: Messages.Message.ContactInfo.Response) -> String {
        if sender.name.isEmpty {
            return sender.email
        }
        return sender.name
    }
    
    private func getContactsGroup(title: String, response: [Messages.Message.ContactInfo.Response]?) -> Messages.Message.Header.ContactsGroup.ViewModel? {
        guard let response = response else { return nil }
        
        let items: [Messages.Message.Header.ContactsGroup.Item.ViewModel] = response.map { self.getContactGroupItem($0) }
        return Messages.Message.Header.ContactsGroup.ViewModel(title: title, items: items)
    }
    
    private func getContactGroupItem(_ contact: Messages.Message.ContactInfo.Response) -> Messages.Message.Header.ContactsGroup.Item.ViewModel {
        let title: String = self.getTitle(contact)
        let menuItems: [MenuItem] = self.getContactMenuItems(contact)
        return Messages.Message.Header.ContactsGroup.Item.ViewModel(title: title, menuItems: menuItems)
    }
    
    private func getContactMenuItems(_ contact: Messages.Message.ContactInfo.Response) -> [MenuItem] {
        let copyAddressTitle: String = NSLocalizedString("contactCopyAddressMenuItemTitle", comment: "")
        return [
            .item(id: .any, title: contact.email, color: nil, state: nil, icon: nil, children: nil, isEnabled: false),
            .separator,
            .item(id: .copyAddress(email: contact.email), title: copyAddressTitle, color: nil, state: nil, icon: nil, children: nil, isEnabled: true)
        ]
    }

}
