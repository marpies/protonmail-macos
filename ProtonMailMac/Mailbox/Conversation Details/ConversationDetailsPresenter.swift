//
//  ConversationDetailsPresenter.swift
//  ProtonMailMac
//
//  Created by Marcel Piešťanský on 17.09.2021.
//  Copyright (c) 2021 marpies. All rights reserved.
//

import AppKit

protocol ConversationDetailsPresentationLogic {
    func presentConversation(response: ConversationDetails.Load.Response)
    func presentLoadError(response: ConversationDetails.LoadError.Response)
    func presentMessageUpdate(response: ConversationDetails.UpdateMessage.Response)
    func presentConversationUpdate(response: ConversationDetails.UpdateConversation.Response)
    func presentMessageContentLoading(response: ConversationDetails.MessageContentLoadDidBegin.Response)
    func presentMessageContentLoaded(response: ConversationDetails.MessageContentLoaded.Response)
    func presentMessageContentCollapsed(response: ConversationDetails.MessageContentCollapsed.Response)
    func presentMessageContentError(response: ConversationDetails.MessageContentError.Response)
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
        let viewModel = ConversationDetails.MessageContentLoaded.ViewModel(messageId: response.messageId, body: response.body)
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
        let header: Messages.Message.Header.ViewModel = Messages.Message.Header.ViewModel(title: response.senderName, labels: labels, folders: folders, date: date, starIcon: starIcon, isRead: response.isRead, draftLabel: draftLabel, repliedIcon: repliedIcon, attachmentIcon: attachmentIcon)
        return Messages.Message.ViewModel(id: response.id, header: header)
    }

}
