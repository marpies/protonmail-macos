//
//  WebSignInPresenter.swift
//  ProtonMailMac
//
//  Created by Marcel Piešťanský on 04.11.2021.
//  Copyright (c) 2021 marpies. All rights reserved.
//

import AppKit

protocol WebSignInPresentationLogic {
	func presentData(response: WebSignIn.Init.Response)
    func presentClearCookies(response: WebSignIn.ClearCookies.Response)
    func presentSignInFinalizing()
    func presentSignInDidComplete()
    func presentSignInError(response: WebSignIn.SignInError.Response)
}

class WebSignInPresenter: WebSignInPresentationLogic {
	weak var viewController: WebSignInDisplayLogic?

	//
	// MARK: - Present initial data
	//

	func presentData(response: WebSignIn.Init.Response) {
        let closeIcon: String? = response.isDismissable ? "xmark" : nil
        let viewModel = WebSignIn.Init.ViewModel(url: response.url, javaScript: response.javaScript, closeIcon: closeIcon)
		self.viewController?.displayData(viewModel: viewModel)
	}
    
    //
    // MARK: - Present clear cookies
    //
    
    func presentClearCookies(response: WebSignIn.ClearCookies.Response) {
        let viewModel = WebSignIn.ClearCookies.ViewModel(domain: response.domain)
        self.viewController?.displayClearCookies(viewModel: viewModel)
    }
    
    //
    // MARK: - Present sign in finalizing
    //
    
    func presentSignInFinalizing() {
        let message: String = NSLocalizedString("webSignInFinalizingMessage", comment: "")
        let viewModel = WebSignIn.DisplayLoading.ViewModel(message: message)
        self.viewController?.displayLoading(viewModel: viewModel)
    }
    
    //
    // MARK: - Present sign in did complete
    //
    
    func presentSignInDidComplete() {
        self.viewController?.displaySignInComplete()
    }
    
    //
    // MARK: - Present sign in error
    //
    
    func presentSignInError(response: WebSignIn.SignInError.Response) {
        let title: String = NSLocalizedString("genericErrorTitle", comment: "")
        let button: String = NSLocalizedString("okButtonTitle", comment: "")
        let message: String
        
        switch response.error {
        case .unsupportedPasswordMode:
            message = NSLocalizedString("signInUnsupportedPasswordModeErrorMessage", comment: "")
        case .keysFailure:
            message = NSLocalizedString("signInKeysFailureErrorMessage", comment: "")
        case .unsupported2FAOption:
            message = NSLocalizedString("signInUnsupported2FAOptionErrorMessage", comment: "")
        case .serverError:
            message = NSLocalizedString("signInServerErrorErrorMessage", comment: "")
        case .userDelinquent:
            message = NSLocalizedString("signInUserDelinquentErrorMessage", comment: "")
        case .incorrectCredentials:
            message = NSLocalizedString("signInIncorrectCredentialsErrorMessage", comment: "")
        case .twoFAInvalid:
            message = NSLocalizedString("signInTwoFactorInvalidErrorMessage", comment: "")
        }
        
        let viewModel = WebSignIn.SignInError.ViewModel(title: title, message: message, button: button)
        self.viewController?.displaySignInError(viewModel: viewModel)
    }

}
