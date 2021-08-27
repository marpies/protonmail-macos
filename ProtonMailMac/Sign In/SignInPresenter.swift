//
//  SignInPresenter.swift
//  ProtonMailMac
//
//  Created by Marcel Piešťanský on 25.08.2021.
//  Copyright (c) 2021 marpies. All rights reserved.
//

import AppKit

protocol SignInPresentationLogic {
    func presentSignIn(response: SignIn.Init.Response)
    func presentSignInDidBegin()
    func presentSignInError(response: SignIn.SignInError.Response)
    func presentSignInDidComplete()
    func presentSignInDidCancel()
    func presentTwoFactorInput()
}

class SignInPresenter: SignInPresentationLogic {
	weak var viewController: SignInDisplayLogic?

	//
	// MARK: - Present initial data
	//

    func presentSignIn(response: SignIn.Init.Response) {
        let title: String = NSLocalizedString("signInTitle", comment: "")
        let usernameTitle: String = NSLocalizedString("signInUsernameTitle", comment: "")
        let passwordTitle: String = NSLocalizedString("signInPasswordTitle", comment: "")
        let signInButtonTitle: String = NSLocalizedString("signInButton", comment: "")
        var cancelButtonTitle: String?
        if response.isDismissable {
            cancelButtonTitle = NSLocalizedString("signInCancelButton", comment: "")
        }
        
        let viewModel = SignIn.Init.ViewModel(title: title, usernameTitle: usernameTitle, passwordTitle: passwordTitle, signInButtonTitle: signInButtonTitle, cancelButtonTitle: cancelButtonTitle)
		self.viewController?.displayInitialData(viewModel: viewModel)
	}
    
    //
    // MARK: - Present sign in did begin
    //
    
    func presentSignInDidBegin() {
        self.viewController?.displaySignInDidBegin()
    }
    
    //
    // MARK: - Present sign in error
    //
    
    func presentSignInError(response: SignIn.SignInError.Response) {
        if let localError = response.localError {
            if localError.contains(.emptyUsername) {
                let placeholder: String = NSLocalizedString("signInEmptyUsernameErrorPlaceholder", comment: "")
                let viewModel = SignIn.InvalidField.ViewModel(type: .username, placeholder: placeholder)
                self.viewController?.displayInvalidField(viewModel: viewModel)
            }
            
            if localError.contains(.emptyPassword) {
                let placeholder: String = NSLocalizedString("signInEmptyPasswordErrorPlaceholder", comment: "")
                let viewModel = SignIn.InvalidField.ViewModel(type: .password, placeholder: placeholder)
                self.viewController?.displayInvalidField(viewModel: viewModel)
            }
        }
        
        if let requestError = response.requestError {
            let title: String = NSLocalizedString("genericErrorTitle", comment: "")
            let button: String = NSLocalizedString("okButtonTitle", comment: "")
            let message: String
            
            switch requestError {
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
            
            let viewModel = SignIn.SignInError.ViewModel(title: title, message: message, button: button)
            self.viewController?.displaySignInError(viewModel: viewModel)
        }
    }
    
    //
    // MARK: - Present sign in did complete
    //
    
    func presentSignInDidComplete() {
        self.viewController?.displaySignInComplete()
    }
    
    //
    // MARK: - Present sign in did cancel
    //
    
    func presentSignInDidCancel() {
        self.viewController?.displaySignInDidCancel()
    }
    
    //
    // MARK: - Present two factor input
    //
    
    func presentTwoFactorInput() {
        self.viewController?.displayTwoFactorInput()
    }

}
