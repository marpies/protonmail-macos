//
//  WebSignInViewController.swift
//  ProtonMailMac
//
//  Created by Marcel Piešťanský on 04.11.2021.
//  Copyright (c) 2021 marpies. All rights reserved.
//

import AppKit

protocol WebSignInDisplayLogic: AnyObject {
	func displayData(viewModel: WebSignIn.Init.ViewModel)
    func displayLoading(viewModel: WebSignIn.DisplayLoading.ViewModel)
    func displayClearCookies(viewModel: WebSignIn.ClearCookies.ViewModel)
    func displaySignInComplete()
    func displaySignInError(viewModel: WebSignIn.SignInError.ViewModel)
}

protocol WebSignInViewControllerDelegate: AnyObject {
    func webSignInDidComplete(_ scene: WebSignInViewController)
    func webSignInDidCancel(_ scene: WebSignInViewController)
}

class WebSignInViewController: NSViewController, WebSignInDisplayLogic, WebSignInViewDelegate {
	
	var interactor: WebSignInBusinessLogic?
	var router: (WebSignInRoutingLogic & WebSignInDataPassing)?

    private let mainView: WebSignInView = WebSignInView()
    
    weak var delegate: WebSignInViewControllerDelegate?
	
	//	
	// MARK: - View lifecycle
	//
    
    override func loadView() {
        self.mainView.delegate = self
        self.view = self.mainView
        self.view.frame = CGRect(x: 0, y: 0, width: CGSize.defaultWindow.width * 0.9, height: CGSize.defaultWindow.height * 0.8)
    }
	
	override func viewDidLoad() {
		super.viewDidLoad()

		self.loadData()
	}
    
    deinit {
        self.mainView.dispose()
    }
	
	//	
	// MARK: - Load data
	//
	
	private func loadData() {
		let request = WebSignIn.Init.Request()
		self.interactor?.loadData(request: request)
	}
	
	func displayData(viewModel: WebSignIn.Init.ViewModel) {
        self.mainView.displayData(viewModel: viewModel)
	}
    
    //
    // MARK: - Display loading
    //
    
    func displayLoading(viewModel: WebSignIn.DisplayLoading.ViewModel) {
        self.mainView.displayLoading(viewModel: viewModel)
    }
    
    //
    // MARK: - Clear cookies
    //
    
    func displayClearCookies(viewModel: WebSignIn.ClearCookies.ViewModel) {
        self.mainView.clearCookies(viewModel: viewModel)
    }
    
    //
    // MARK: - Sign in complete
    //
    
    func displaySignInComplete() {
        self.delegate?.webSignInDidComplete(self)
    }
    
    //
    // MARK: - Sign in error
    //
    
    func displaySignInError(viewModel: WebSignIn.SignInError.ViewModel) {
        self.mainView.displaySignInError(viewModel: viewModel)
    }
    
    //
    // MARK: - View delegate
    //
    
    func signInCookiesDidUpdate(_ cookies: [HTTPCookie]) {
        let request: WebSignIn.ProcessCookies.Request = WebSignIn.ProcessCookies.Request(cookies: cookies)
        self.interactor?.processCookies(request: request)
    }
    
    func signInPasswordDidReceive(_ password: String, passwordMode: Int) {
        let request: WebSignIn.ProcessPassword.Request = WebSignIn.ProcessPassword.Request(password: password, passwordMode: passwordMode)
        self.interactor?.processPassword(request: request)
    }
    
    func signInViewCloseButtonDidTap() {
        self.delegate?.webSignInDidCancel(self)
    }
    
    func signInErrorAlertDidConfirm() {
        let request: WebSignIn.SignInErrorAlertConfirmation.Request = WebSignIn.SignInErrorAlertConfirmation.Request()
        self.interactor?.processSignInErrorAlertConfirmation(request: request)
    }
    
}
