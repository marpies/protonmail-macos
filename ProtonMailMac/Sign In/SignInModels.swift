//
//  SignInModels.swift
//  ProtonMailMac
//
//  Created by Marcel Piešťanský on 25.08.2021.
//  Copyright (c) 2021 marpies. All rights reserved.
//

import Foundation

enum SignIn {
    
    enum FieldType {
        case username, password
    }

	//
	// MARK: - Init
	//

	enum Init {
		struct Request {
		}
        
        struct Response {
            let isDismissable: Bool
        }

		class ViewModel {
            let title: String
            let usernameTitle: String
            let passwordTitle: String
            let signInButtonTitle: String
            let cancelButtonTitle: String?

            init(title: String, usernameTitle: String, passwordTitle: String, signInButtonTitle: String, cancelButtonTitle: String?) {
                self.title = title
                self.usernameTitle = usernameTitle
                self.passwordTitle = passwordTitle
                self.signInButtonTitle = signInButtonTitle
                self.cancelButtonTitle = cancelButtonTitle
            }
		}
	}
    
    //
    // MARK: - Sign in
    //
    
    enum ProcessSignIn {
        struct Request {
            let username: String
            let password: String
        }
    }
    
    //
    // MARK: - Sign in error
    //
    
    enum SignInError {
        struct LocalError: OptionSet {
            let rawValue: Int
            
            static let emptyUsername: LocalError = LocalError(rawValue: 1 << 0)
            static let emptyPassword: LocalError = LocalError(rawValue: 1 << 1)
        }
        
        enum RequestError: Error {
            case unsupportedPasswordMode
            case keysFailure
            case unsupported2FAOption
            case incorrectCredentials
            case serverError
            case userDelinquent
            case twoFAInvalid
        }
        
        struct Response {
            let localError: SignIn.SignInError.LocalError?
            let requestError: SignIn.SignInError.RequestError?
            
            init(localError: SignIn.SignInError.LocalError) {
                self.localError = localError
                self.requestError = nil
            }
            
            init(requestError: SignIn.SignInError.RequestError) {
                self.requestError = requestError
                self.localError = nil
            }
        }
        
        class ViewModel {
            let title: String
            let message: String
            let button: String

            init(title: String, message: String, button: String) {
                self.title = title
                self.message = message
                self.button = button
            }
        }
    }
    
    //
    // MARK: - Invalid field
    //
    
    enum InvalidField {
        struct ViewModel {
            let type: SignIn.FieldType
            let placeholder: String
        }
    }
    
    //
    // MARK: - Process two-factor input
    //
    
    enum TwoFactorInput {
        struct Request {
            let code: String?
        }
    }
    
    //
    // MARK: - Display captcha
    //
    
    enum DisplayCaptcha {
        struct Response {
            let startToken: String?
        }
    }
    
    //
    // MARK: - Captcha challenge pass
    //
    
    enum CaptchaChallengePass {
        struct Request {
            let token: String
        }
    }
    
}
