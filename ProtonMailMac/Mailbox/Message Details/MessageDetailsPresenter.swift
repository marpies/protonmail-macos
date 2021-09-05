//
//  MessageDetailsPresenter.swift
//  ProtonMailMac
//
//  Created by Marcel Piešťanský on 05.09.2021.
//  Copyright (c) 2021 marpies. All rights reserved.
//

import AppKit

protocol MessageDetailsPresentationLogic {
	func presentData(response: MessageDetails.Init.Response)
}

class MessageDetailsPresenter: MessageDetailsPresentationLogic {
	weak var viewController: MessageDetailsDisplayLogic?

	//
	// MARK: - Present initial data
	//

	func presentData(response: MessageDetails.Init.Response) {
		let viewModel = MessageDetails.Init.ViewModel()
		self.viewController?.displayData(viewModel: viewModel)
	}

}
