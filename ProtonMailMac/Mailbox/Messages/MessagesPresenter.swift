//
//  MessagesPresenter.swift
//  ProtonMailMac
//
//  Created by Marcel Piešťanský on 05.09.2021.
//  Copyright (c) 2021 marpies. All rights reserved.
//

import AppKit

protocol MessagesPresentationLogic {
	func presentData(response: Messages.Init.Response)
}

class MessagesPresenter: MessagesPresentationLogic {
	weak var viewController: MessagesDisplayLogic?

	//
	// MARK: - Present initial data
	//

	func presentData(response: Messages.Init.Response) {
		let viewModel = Messages.Init.ViewModel()
		self.viewController?.displayData(viewModel: viewModel)
	}

}
