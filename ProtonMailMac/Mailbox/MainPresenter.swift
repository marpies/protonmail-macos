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

}
