//
//  RecaptchaViewController.swift
//  ProtonMailMac
//
//  Created by Marcel Piešťanský on 01.11.2021.
//  Copyright (c) 2021 marpies. All rights reserved.
//

import AppKit

protocol RecaptchaDisplayLogic: AnyObject {
	func displayData(viewModel: Recaptcha.Init.ViewModel)
}

protocol RecaptchaViewControllerDelegate: AnyObject {
    func recaptchaDidCancel(_ scene: RecaptchaViewController)
    func recaptchaChallengeDidPass(_ scene: RecaptchaViewController, token: String)
}

class RecaptchaViewController: NSViewController, RecaptchaDisplayLogic, RecaptchaViewDelegate {
	
	var interactor: RecaptchaBusinessLogic?
	var router: (RecaptchaRoutingLogic & RecaptchaDataPassing)?
    
    weak var delegate: RecaptchaViewControllerDelegate?

    private let mainView: RecaptchaView = RecaptchaView()
    
    deinit {
        self.mainView.dispose()
    }
	
	//	
	// MARK: - View lifecycle
	//
    
    override func loadView() {
        self.mainView.delegate = self
        self.view = self.mainView
        self.view.frame = CGRect(x: 0, y: 0, width: CGSize.defaultWindow.width / 2, height: CGSize.defaultWindow.height * 0.8)
    }
	
	override func viewDidLoad() {
		super.viewDidLoad()

		self.loadData()
	}
	
	//	
	// MARK: - Load data
	//
	
	private func loadData() {
		let request = Recaptcha.Init.Request()
		self.interactor?.loadData(request: request)
	}
	
	func displayData(viewModel: Recaptcha.Init.ViewModel) {
        self.mainView.displayData(viewModel: viewModel)
	}
    
    //
    // MARK: - View delegate
    //
    
    func captchaViewCloseButtonDidTap() {
        self.delegate?.recaptchaDidCancel(self)
    }
    
    func captchaChallengeDidPass(token: String) {
        self.delegate?.recaptchaChallengeDidPass(self, token: token)
    }
    
}
