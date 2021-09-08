//
//  MailboxSidebarPresenter.swift
//  ProtonMailMac
//
//  Created by Marcel Piešťanský on 27.08.2021.
//  Copyright (c) 2021 marpies. All rights reserved.
//

import AppKit

protocol MailboxSidebarPresentationLogic {
	func presentData(response: MailboxSidebar.Init.Response)
    func presentSidebarRefresh(response: MailboxSidebar.RefreshGroups.Response)
}

class MailboxSidebarPresenter: MailboxSidebarPresentationLogic {
	weak var viewController: MailboxSidebarDisplayLogic?

	//
	// MARK: - Present initial data
	//

	func presentData(response: MailboxSidebar.Init.Response) {
        let groups: [MailboxSidebar.Group.ViewModel] = response.groups.map { self.getGroup(response: $0) }
        let viewModel = MailboxSidebar.Init.ViewModel(groups: groups, selectedRow: response.selectedRow)
		self.viewController?.displayData(viewModel: viewModel)
	}
    
    //
    // MARK: - Present sidebar refresh
    //
    
    func presentSidebarRefresh(response: MailboxSidebar.RefreshGroups.Response) {
        let groups: [MailboxSidebar.Group.ViewModel] = response.groups.map { self.getGroup(response: $0) }
        let viewModel = MailboxSidebar.RefreshGroups.ViewModel(groups: groups, selectedRow: response.selectedRow)
        self.viewController?.displayGroupsRefresh(viewModel: viewModel)
    }
    
    //
    // MARK: - Private
    //
    
    private func getGroup(response: MailboxSidebar.Group.Response) -> MailboxSidebar.Group.ViewModel {
        let title: String
        
        switch response.kind {
        case .inboxes:
            title = NSLocalizedString("mailboxInboxesGroupTitle", comment: "")
        case .folders:
            title = NSLocalizedString("mailboxFoldersGroupTitle", comment: "")
        case .labels:
            title = NSLocalizedString("mailboxLabelsGroupTitle", comment: "")
        }
        
        let labels = response.labels.map { self.getItem(response: $0) }
        return MailboxSidebar.Group.ViewModel(title: title, labels: labels)
    }
    
    private func getItem(response: MailboxSidebar.Item.Response) -> MailboxSidebar.Item.ViewModel {
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
            
            if isFolder {
                let hasChildren: Bool = !(response.children?.isEmpty ?? true)
                icon = hasChildren ? "plus.rectangle.on.folder" : "folder"
            } else {
                icon = "tag"
            }
        }
        
        let children = response.children?.map { self.getItem(response: $0) }
        
        return MailboxSidebar.Item.ViewModel(id: response.kind.id, title: title, icon: icon, children: children, color: response.color)
    }

}
