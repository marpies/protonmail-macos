//
//  TwoFactorInputPresenter.swift
//  ProtonMailMac
//
//  Created by Marcel Piešťanský on 26.08.2021.
//  Copyright (c) 2021 marpies. All rights reserved.
//

import AppKit

protocol TwoFactorInputPresentationLogic {
	func presentInitialData(response: TwoFactorInput.Init.Response)
    func presentInvalidField()
    func presentSceneDismiss()
}

class TwoFactorInputPresenter: TwoFactorInputPresentationLogic {
	weak var viewController: TwoFactorInputDisplayLogic?

	//
	// MARK: - Present initial data
	//

    func presentInitialData(response: TwoFactorInput.Init.Response) {
        let title: String = NSLocalizedString("twoFactorInputTitle", comment: "")
        let fieldTitle: String = NSLocalizedString("twoFactorInputFieldTitle", comment: "")
        let confirmButtonTitle: String = NSLocalizedString("twoFactorInputButton", comment: "")
        let cancelButtonTitle: String = NSLocalizedString("twoFactorCancelButton", comment: "")
		let viewModel = TwoFactorInput.Init.ViewModel(title: title, fieldTitle: fieldTitle, confirmButtonTitle: confirmButtonTitle, cancelButtonTitle: cancelButtonTitle)
		self.viewController?.displayInitialData(viewModel: viewModel)
	}
    
    //
    // MARK: - Present invalid field
    //
    
    func presentInvalidField() {
        let placeholder: String = NSLocalizedString("twoFactorInputEmptyFieldErrorPlaceholder", comment: "")
        let viewModel = TwoFactorInput.InvalidField.ViewModel(placeholder: placeholder)
        self.viewController?.displayInvalidField(viewModel: viewModel)
    }
    
    //
    // MARK: - Present scene dismiss
    //
    
    func presentSceneDismiss() {
        self.viewController?.displaySceneDismissal()
    }

}
