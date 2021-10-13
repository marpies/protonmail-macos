//
//  MainPresenter.swift
//  ProtonMailMac
//
//  Created by Marcel Piešťanský on 25.08.2021.
//  Copyright (c) 2021 marpies. All rights reserved.
//

import AppKit

protocol MainPresentationLogic {
	func presentData(response: Main.Init.Response)
    func presentTitle(response: Main.LoadTitle.Response)
    func presentToolbar(response: Main.UpdateToolbar.Response)
}

class MainPresenter: MainPresentationLogic {
	weak var viewController: MainDisplayLogic?

	//
	// MARK: - Present initial data
	//

	func presentData(response: Main.Init.Response) {
        let message: String = NSLocalizedString("mailboxLoadingMessage", comment: "")
		let viewModel = Main.Init.ViewModel(loadingMessage: message)
		self.viewController?.displayData(viewModel: viewModel)
	}
    
    //
    // MARK: - Present title
    //
    
    func presentTitle(response: Main.LoadTitle.Response) {
        let title: String
        var isMessages: Bool = false
        
        switch response.item {
        case .draft:
            title = NSLocalizedString("mailboxLabelDrafts", comment: "")
            isMessages = true
        case .inbox:
            title = NSLocalizedString("mailboxLabelInbox", comment: "")
        case .outbox:
            title = NSLocalizedString("mailboxLabelSent", comment: "")
            isMessages = true
        case .spam:
            title = NSLocalizedString("mailboxLabelSpam", comment: "")
        case .archive:
            title = NSLocalizedString("mailboxLabelArchive", comment: "")
        case .trash:
            title = NSLocalizedString("mailboxLabelTrash", comment: "")
        case .allMail:
            title = NSLocalizedString("mailboxLabelAllMail", comment: "")
        case .starred:
            title = NSLocalizedString("mailboxLabelStarred", comment: "")
        case .custom(_, let name, _):
            title = name
        }
        
        var subtitle: String?
        
        if #available(macOS 11.0, *) {
            let format: String
            if isMessages {
                format = NSLocalizedString("num_messages", comment: "")
            } else {
                format = NSLocalizedString("num_conversations", comment: "")
            }
            
            subtitle = String.localizedStringWithFormat(format, response.numItems)
        }
        
        let viewModel = Main.LoadTitle.ViewModel(title: title, subtitle: subtitle)
        self.viewController?.displayTitle(viewModel: viewModel)
    }
    
    //
    // MARK: - Present toolbar
    //
    
    func presentToolbar(response: Main.UpdateToolbar.Response) {
        let identifiers: [NSToolbarItem.Identifier] = self.toolbarIdentifiers
        
        let items: [Main.ToolbarItem.ViewModel] = identifiers.map {
            self.getToolbarItem(id: $0, isSelectionActive: response.isSelectionActive, isMultiSelection: response.isMultiSelection)
        }
        
        let viewModel = Main.UpdateToolbar.ViewModel(identifiers: identifiers, items: items)
        self.viewController?.displayToolbarUpdate(viewModel: viewModel)
    }
    
    //
    // MARK: - Private
    //
    
    private var toolbarIdentifiers: [NSToolbarItem.Identifier] {
        var identifiers: [NSToolbarItem.Identifier] = []
        
        if #available(macOS 11.0, *) {
            identifiers.append(.trackingItem2)
        }
        
        identifiers.append(contentsOf: [
            .refreshMailbox,
            .flexibleSpace,
            .moveToGroup,
            .replyForwardGroup
        ])
        
        return identifiers
    }
    
    private func getToolbarItem(id: NSToolbarItem.Identifier, isSelectionActive: Bool, isMultiSelection: Bool) -> Main.ToolbarItem.ViewModel {
        switch id {
        case .trackingItem1:
            return .trackingItem(id: id, index: 0)
            
        case .trackingItem2:
            return .trackingItem(id: id, index: 1)
            
        case .refreshMailbox, .moveToArchive, .moveToTrash, .moveToSpam, .replyToSender, .replyToAll, .forwardMessage:
            let label: String = self.getToolbarItemLabel(id: id)
            let tooltip: String = self.getToolbarItemTooltip(id: id)
            let icon: String = self.getToolbarItemIcon(id: id)
            let isEnabled: Bool = self.getToolbarItemEnabled(id: id, isSelectionActive: isSelectionActive, isMultiSelection: isMultiSelection)
            return .button(id: id, label: label, tooltip: tooltip, icon: icon, isEnabled: isEnabled)
            
        case .replyForwardGroup:
            return .group(id: id, items: [
                self.getToolbarItem(id: .replyToSender, isSelectionActive: isSelectionActive, isMultiSelection: isMultiSelection),
                self.getToolbarItem(id: .replyToAll, isSelectionActive: isSelectionActive, isMultiSelection: isMultiSelection),
                self.getToolbarItem(id: .forwardMessage, isSelectionActive: isSelectionActive, isMultiSelection: isMultiSelection)
            ])
            
        case .moveToGroup:
            return .group(id: id, items: [
                self.getToolbarItem(id: .moveToArchive, isSelectionActive: isSelectionActive, isMultiSelection: isMultiSelection),
                self.getToolbarItem(id: .moveToTrash, isSelectionActive: isSelectionActive, isMultiSelection: isMultiSelection),
                self.getToolbarItem(id: .moveToSpam, isSelectionActive: isSelectionActive, isMultiSelection: isMultiSelection)
            ])
            
        case .flexibleSpace, .space:
            return .spacer
            
        default:
            fatalError("Unknown toolbar item id: \(id.rawValue).")
        }
    }
    
    private func getToolbarItemLabel(id: NSToolbarItem.Identifier) -> String {
        switch id {
        case .refreshMailbox:
            return NSLocalizedString("toolbarRefreshMailboxLabel", comment: "")
        case .moveToArchive:
            return NSLocalizedString("toolbarMoveToArchiveLabel", comment: "")
        case .moveToTrash:
            return NSLocalizedString("toolbarMoveToTrashLabel", comment: "")
        case .moveToSpam:
            return NSLocalizedString("toolbarMoveToSpamLabel", comment: "")
        case .replyToSender:
            return NSLocalizedString("toolbarReplyToSenderLabel", comment: "")
        case .replyToAll:
            return NSLocalizedString("toolbarReplyToAllLabel", comment: "")
        case .forwardMessage:
            return NSLocalizedString("toolbarForwardMessagesLabel", comment: "")
        default:
            fatalError("Toolbar item \(id.rawValue) does not have a label.")
        }
    }
    
    private func getToolbarItemTooltip(id: NSToolbarItem.Identifier) -> String {
        switch id {
        case .refreshMailbox:
            return NSLocalizedString("toolbarRefreshMailboxTooltip", comment: "")
        case .moveToArchive:
            return NSLocalizedString("toolbarMoveToArchiveTooltip", comment: "")
        case .moveToTrash:
            return NSLocalizedString("toolbarMoveToTrashTooltip", comment: "")
        case .moveToSpam:
            return NSLocalizedString("toolbarMoveToSpamTooltip", comment: "")
        case .replyToSender:
            return NSLocalizedString("toolbarReplyToSenderTooltip", comment: "")
        case .replyToAll:
            return NSLocalizedString("toolbarReplyToAllTooltip", comment: "")
        case .forwardMessage:
            return NSLocalizedString("toolbarForwardMessagesTooltip", comment: "")
        default:
            fatalError("Toolbar item \(id.rawValue) does not have a tooltip.")
        }
    }
    
    private func getToolbarItemIcon(id: NSToolbarItem.Identifier) -> String {
        switch id {
        case .refreshMailbox:
            return "envelope"
        case .moveToArchive:
            return "archivebox"
        case .moveToTrash:
            return "trash"
        case .moveToSpam:
            return "flame"
        case .replyToSender:
            return "arrowshape.turn.up.left"
        case .replyToAll:
            return "arrowshape.turn.up.left.2"
        case .forwardMessage:
            return "arrowshape.turn.up.right"
        default:
            fatalError("Toolbar item \(id.rawValue) does not have an icon.")
        }
    }
    
    private func getToolbarItemEnabled(id: NSToolbarItem.Identifier, isSelectionActive: Bool, isMultiSelection: Bool) -> Bool {
        switch id {
        case .moveToArchive, .moveToTrash, .moveToSpam, .forwardMessage:
            return isSelectionActive
        case .replyToSender, .replyToAll:
            return isSelectionActive && !isMultiSelection
        default:
            return true
        }
    }

}
