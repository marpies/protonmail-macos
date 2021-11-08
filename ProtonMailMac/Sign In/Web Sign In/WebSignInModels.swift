//
//  WebSignInModels.swift
//  ProtonMailMac
//
//  Created by Marcel Piešťanský on 04.11.2021.
//  Copyright (c) 2021 marpies. All rights reserved.
//

import Foundation

enum WebSignIn {

	//
	// MARK: - Init
	//

	enum Init {
		struct Request {
		}

		struct Response {
            let url: URLRequest
            let javaScript: String
            let isDismissable: Bool
		}

		struct ViewModel {
            let url: URLRequest
            let javaScript: String
            let closeIcon: String?
		}
	}
    
    //
    // MARK: - Sign in error
    //
    
    enum SignInError {
        struct Response {
            let error: SignIn.SignInError.RequestError
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
    // MARK: - Process password
    //
    
    enum ProcessPassword {
        struct Request {
            let password: String
            let passwordMode: Int
        }
    }
    
    //
    // MARK: - Process cookies
    //
    
    enum ProcessCookies {
        class Request {
            let cookies: [HTTPCookie]

            init(cookies: [HTTPCookie]) {
                self.cookies = cookies
            }
        }
    }
    
    //
    // MARK: - Clear cookies
    //
    
    enum ClearCookies {
        struct Response {
            let domain: String
        }
        
        struct ViewModel {
            let domain: String
        }
    }
    
    //
    // MARK: - Display loading
    //
    
    enum DisplayLoading {
        struct ViewModel {
            let message: String
        }
    }
    
    //
    // MARK: - Sign in error alert confirmation
    //
    
    enum SignInErrorAlertConfirmation {
        struct Request {
            
        }
    }
    
}
