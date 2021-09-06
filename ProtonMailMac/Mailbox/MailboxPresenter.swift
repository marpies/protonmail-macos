//
//  MailboxPresenter.swift
//  ProtonMailMac
//
//  Created by Marcel Piešťanský on 25.08.2021.
//  Copyright (c) 2021 marpies. All rights reserved.
//

import AppKit

protocol MailboxPresentationLogic {
	func presentData(response: Mailbox.Init.Response)
}

class MailboxPresenter: MailboxPresentationLogic {
	weak var viewController: MailboxDisplayLogic?

	//
	// MARK: - Present initial data
	//

	func presentData(response: Mailbox.Init.Response) {
        let message: String = NSLocalizedString("mailboxLoadingMessage", comment: "")
		let viewModel = Mailbox.Init.ViewModel(loadingMessage: message)
		self.viewController?.displayData(viewModel: viewModel)
	}

}
