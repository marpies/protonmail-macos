//
//  ConversationDetailsPresenter.swift
//  ProtonMailMac
//
//  Created by Marcel Piešťanský on 17.09.2021.
//  Copyright (c) 2021 marpies. All rights reserved.
//

import AppKit

protocol ConversationDetailsPresentationLogic {
	func presentData(response: ConversationDetails.Init.Response)
}

class ConversationDetailsPresenter: ConversationDetailsPresentationLogic {
	weak var viewController: ConversationDetailsDisplayLogic?

	//
	// MARK: - Present initial data
	//

	func presentData(response: ConversationDetails.Init.Response) {
		let viewModel = ConversationDetails.Init.ViewModel()
		self.viewController?.displayData(viewModel: viewModel)
	}

}
