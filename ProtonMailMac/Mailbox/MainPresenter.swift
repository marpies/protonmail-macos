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
            self.getToolbarItem(id: $0, response: response)
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
            .replyForwardGroup,
            .setLabels,
            .moveToFolder
        ])
        
        return identifiers
    }
    
    private var noLabelsMenuItem: Main.ToolbarItem.MenuItem.ViewModel {
        let title: String = NSLocalizedString("toolbarNoLabelsMenuItem", comment: "")
        return Main.ToolbarItem.MenuItem.ViewModel(id: "", title: title, color: nil, state: nil, icon: nil, children: nil, isEnabled: false)
    }
    
    private var noFoldersMenuItem: Main.ToolbarItem.MenuItem.ViewModel {
        let title: String = NSLocalizedString("toolbarNoFoldersMenuItem", comment: "")
        return Main.ToolbarItem.MenuItem.ViewModel(id: "", title: title, color: nil, state: nil, icon: nil, children: nil, isEnabled: false)
    }
    
    private func getToolbarItem(id: NSToolbarItem.Identifier, response: Main.UpdateToolbar.Response) -> Main.ToolbarItem.ViewModel {
        switch id {
        case .trackingItem1:
            return .trackingItem(id: id, index: 0)
            
        case .trackingItem2:
            return .trackingItem(id: id, index: 1)
            
        case .refreshMailbox, .moveToArchive, .moveToTrash, .moveToSpam, .replyToSender, .replyToAll, .forwardMessage:
            let label: String = self.getToolbarItemLabel(id: id)
            let tooltip: String = self.getToolbarItemTooltip(id: id)
            let icon: String = self.getToolbarItemIcon(id: id)
            let isEnabled: Bool = self.getToolbarItemEnabled(id: id, isSelectionActive: response.isSelectionActive, isMultiSelection: response.isMultiSelection)
            return .button(id: id, label: label, tooltip: tooltip, icon: icon, isEnabled: isEnabled)
            
        case .replyForwardGroup:
            return .group(id: id, items: [
                self.getToolbarItem(id: .replyToSender, response: response),
                self.getToolbarItem(id: .replyToAll, response: response),
                self.getToolbarItem(id: .forwardMessage, response: response)
            ])
            
        case .moveToGroup:
            return .group(id: id, items: [
                self.getToolbarItem(id: .moveToArchive, response: response),
                self.getToolbarItem(id: .moveToTrash, response: response),
                self.getToolbarItem(id: .moveToSpam, response: response)
            ])
            
        case .flexibleSpace, .space:
            return .spacer
            
        case .setLabels:
            let label: String = self.getToolbarItemLabel(id: id)
            let tooltip: String = self.getToolbarItemTooltip(id: id)
            let icon: String = self.getToolbarItemIcon(id: id)
            let isEnabled: Bool = self.getToolbarItemEnabled(id: id, isSelectionActive: response.isSelectionActive, isMultiSelection: response.isMultiSelection)
            let items: [Main.ToolbarItem.MenuItem.ViewModel]
            if let labels = response.labelItems {
                items = labels.map { self.getMenuItem(response: $0) }
            } else {
                items = [self.noLabelsMenuItem]
            }
            return .imageMenu(id: id, label: label, tooltip: tooltip, icon: icon, isEnabled: isEnabled, items: items)
            
        case .moveToFolder:
            let title: String = NSLocalizedString("toolbarMoveToButtonTitle", comment: "")
            let label: String = self.getToolbarItemLabel(id: id)
            let tooltip: String = self.getToolbarItemTooltip(id: id)
            let icon: String = self.getToolbarItemIcon(id: id)
            let isEnabled: Bool = self.getToolbarItemEnabled(id: id, isSelectionActive: response.isSelectionActive, isMultiSelection: response.isMultiSelection)
            let items: [Main.ToolbarItem.MenuItem.ViewModel]
            if let folders = response.folderItems {
                items = folders.map { self.getMenuItem(response: $0) }
            } else {
                items = [self.noFoldersMenuItem]
            }
            return .buttonMenu(id: id, title: title, label: label, tooltip: tooltip, icon: icon, isEnabled: isEnabled, items: items)
            
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
        case .setLabels:
            return NSLocalizedString("toolbarSetLabelsLabel", comment: "")
        case .moveToFolder:
            return NSLocalizedString("toolbarMoveToFolderLabel", comment: "")
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
        case .setLabels:
            return NSLocalizedString("toolbarSetLabelsTooltip", comment: "")
        case .moveToFolder:
            return NSLocalizedString("toolbarMoveToFolderTooltip", comment: "")
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
        case .setLabels:
            return "tag"
        case .moveToFolder:
            return "folder"
        default:
            fatalError("Toolbar item \(id.rawValue) does not have an icon.")
        }
    }
    
    private func getToolbarItemEnabled(id: NSToolbarItem.Identifier, isSelectionActive: Bool, isMultiSelection: Bool) -> Bool {
        switch id {
        case .moveToArchive, .moveToTrash, .moveToSpam, .forwardMessage, .setLabels, .moveToFolder:
            return isSelectionActive
        case .replyToSender, .replyToAll:
            return isSelectionActive && !isMultiSelection
        default:
            return true
        }
    }
    
    private func getMenuItem(response: Main.ToolbarItem.MenuItem.Response) -> Main.ToolbarItem.MenuItem.ViewModel {
        let state: NSControl.StateValue?
        switch response.state {
        case .none:
            state = nil
        case .some(let val):
            switch val {
            case .off:
                state = .off
            case .on:
                state = .on
            case .mixed:
                state = .mixed
            }
        }
        
        return self.getMenuItem(response: response.item, state: state)
    }
    
    private func getMenuItem(response: MailboxSidebar.Item.Response, state: NSControl.StateValue?) -> Main.ToolbarItem.MenuItem.ViewModel {
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
        case .allMail:
            title = NSLocalizedString("mailboxLabelAllMail", comment: "")
            icon = "mail.stack"
        case .starred:
            title = NSLocalizedString("mailboxLabelStarred", comment: "")
            icon = "star"
        case .custom(_, let name, let isFolder):
            title = name
            icon = isFolder ? "folder" : "tag"
        }
        
        let children: [Main.ToolbarItem.MenuItem.ViewModel]? = response.children?.map { self.getMenuItem(response: $0, state: nil) }
        
        return Main.ToolbarItem.MenuItem.ViewModel(id: response.kind.id, title: title, color: response.color, state: state, icon: icon, children: children)
    }

}
