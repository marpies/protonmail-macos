//
//  MessageFolderPresenting.swift
//  ProtonMailMac
//
//  Created by Marcel Piešťanský on 17.09.2021.
//  Copyright © 2021 marpies. All rights reserved.
//

import Foundation

protocol MessageFolderPresenting {
    func getFolder(response: Messages.Folder.Response) -> Messages.Folder.ViewModel
}

extension MessageFolderPresenting {
    
    func getFolder(response: Messages.Folder.Response) -> Messages.Folder.ViewModel {
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
    
}
