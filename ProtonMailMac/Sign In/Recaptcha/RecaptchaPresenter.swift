//
//  RecaptchaPresenter.swift
//  ProtonMailMac
//
//  Created by Marcel Piešťanský on 01.11.2021.
//  Copyright (c) 2021 marpies. All rights reserved.
//

import AppKit

protocol RecaptchaPresentationLogic {
	func presentData(response: Recaptcha.Init.Response)
}

class RecaptchaPresenter: RecaptchaPresentationLogic {
	weak var viewController: RecaptchaDisplayLogic?

	//
	// MARK: - Present initial data
	//

	func presentData(response: Recaptcha.Init.Response) {
        let viewModel = Recaptcha.Init.ViewModel(url: response.url, closeIcon: "xmark")
		self.viewController?.displayData(viewModel: viewModel)
	}

}
