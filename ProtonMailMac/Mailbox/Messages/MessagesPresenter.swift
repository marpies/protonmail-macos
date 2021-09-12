//
//  MessagesPresenter.swift
//  ProtonMailMac
//
//  Created by Marcel Piešťanský on 05.09.2021.
//  Copyright (c) 2021 marpies. All rights reserved.
//

import AppKit

protocol MessagesPresentationLogic {
	func presentMessages(response: Messages.LoadMessages.Response)
    func presentMessagesUpdate(response: Messages.UpdateMessages.Response)
    func presentMessagesError(response: Messages.LoadError.Response)
    func presentMessagesUpToDate()
}

class MessagesPresenter: MessagesPresentationLogic {
	weak var viewController: MessagesDisplayLogic?
    
    private let dateFormatter: DateFormatter
    
    init() {
        self.dateFormatter = DateFormatter()
        self.dateFormatter.locale = Locale.current
    }

	//
	// MARK: - Present messages
	//

	func presentMessages(response: Messages.LoadMessages.Response) {
        let messages: [Messages.Message.ViewModel] = response.messages.map { self.getMessage(response: $0) }
        let viewModel = Messages.LoadMessages.ViewModel(messages: messages, removeErrorView: response.isServerResponse)
		self.viewController?.displayMessages(viewModel: viewModel)
	}
    
    //
    // MARK: - Present messages update
    //
    
    func presentMessagesUpdate(response: Messages.UpdateMessages.Response) {
        let messages: [Messages.Message.ViewModel] = response.messages.map { self.getMessage(response: $0) }
        let viewModel = Messages.UpdateMessages.ViewModel(messages: messages, removeSet: response.removeSet, insertSet: response.insertSet, updateSet: response.updateSet)
        self.viewController?.displayMessagesUpdate(viewModel: viewModel)
    }
    
    //
    // MARK: - Present messages error
    //
    
    func presentMessagesError(response: Messages.LoadError.Response) {
        let message: String
        
        if response.error.isInternetError() {
            message = NSLocalizedString("messagesLoadInternetErrorMessage", comment: "")
        } else {
            message = NSLocalizedString("messagesLoadGenericErrorMessage", comment: "")
        }
        
        let button: String = NSLocalizedString("messagesRetryLoadButton", comment: "")
        
        let viewModel = Messages.LoadError.ViewModel(message: message, button: button)
        self.viewController?.displayMessagesError(viewModel: viewModel)
    }
    
    //
    // MARK: - Present messages up to date
    //
    
    func presentMessagesUpToDate() {
        self.viewController?.displayMessagesUpToDate()
    }
    
    //
    // MARK: - Private
    //
    
    private func getMessage(response: Messages.Message.Response) -> Messages.Message.ViewModel {
        let time: String = self.getMessageTime(response: response.time)
        let folders: [Messages.Folder.ViewModel]? = response.folders?.map { self.getFolder(response: $0) }
        let labels: [Messages.Label.ViewModel]? = response.labels?.map { self.getLabel(response: $0) }
        var attachmentIcon: Messages.Attachment.ViewModel? = nil
        if response.numAttachments > 0 {
            let format: String = NSLocalizedString("num_attachments", comment: "")
            let title: String = String.localizedStringWithFormat(format, response.numAttachments)
            attachmentIcon = Messages.Attachment.ViewModel(icon: "paperclip", title: title)
        }
        return Messages.Message.ViewModel(id: response.id, title: response.senderName, subtitle: response.subject, time: time, isStarred: response.isStarred, isRead: response.isRead, folders: folders, labels: labels, attachmentIcon: attachmentIcon)
    }
    
    private func getMessageTime(response: Messages.MessageTime) -> String {
        let date: Date
        
        switch response {
        case .today(let messageDate):
            // Show time only
            date = messageDate
            self.dateFormatter.dateStyle = .none
            self.dateFormatter.timeStyle = .short
            
        case .yesterday(_):
            // Show "Yesterday"
            return NSLocalizedString("messageDateYesterdayText", comment: "")
            
        case .other(let messageDate):
            // Show date without time
            date = messageDate
            self.dateFormatter.dateStyle = .long
            self.dateFormatter.timeStyle = .none
        }
        
        return self.dateFormatter.string(from: date)
    }
    
    private func getFolder(response: Messages.Folder.Response) -> Messages.Folder.ViewModel {
        let title: String
        let icon: String
        
        switch response.kind {
        case .draft:
            title = NSLocalizedString("mailboxLabelDrafts", comment: "")
            icon = "note.text"
        case .inbox:
            title = NSLocalizedString("mailboxLabelInbox", comment: "")
            icon = "tray"
        case .outbox:
            title = NSLocalizedString("mailboxLabelSent", comment: "")
            icon = "paperplane"
        case .spam:
            title = NSLocalizedString("mailboxLabelSpam", comment: "")
            icon = "flame"
        case .archive:
            title = NSLocalizedString("mailboxLabelArchive", comment: "")
            icon = "archivebox"
        case .trash:
            title = NSLocalizedString("mailboxLabelTrash", comment: "")
            icon = "trash"
        case .custom(_, let name):
            title = name
            icon = "folder"
        }
        
        return Messages.Folder.ViewModel(id: response.kind.id, title: title, icon: icon, color: response.color)
    }
    
    private func getLabel(response: Messages.Label.Response) -> Messages.Label.ViewModel {
        return Messages.Label.ViewModel(id: response.id, title: response.title, color: response.color)
    }

}
