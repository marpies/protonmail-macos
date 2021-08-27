//
//  SignInViewController.swift
//  ProtonMailMac
//
//  Created by Marcel Piešťanský on 25.08.2021.
//  Copyright (c) 2021 marpies. All rights reserved.
//

import AppKit
import Swinject

protocol SignInDisplayLogic: AnyObject {
	func displayInitialData(viewModel: SignIn.Init.ViewModel)
    func displaySignInDidBegin()
    func displaySignInError(viewModel: SignIn.SignInError.ViewModel)
    func displayInvalidField(viewModel: SignIn.InvalidField.ViewModel)
    func displaySignInComplete()
    func displaySignInDidCancel()
    func displayTwoFactorInput()
}

protocol SignInViewControllerDelegate: AnyObject {
    func signInDidComplete(_ scene: SignInViewController)
}

class SignInViewController: NSViewController, SignInDisplayLogic, SignInViewDelegate, TwoFactorInputViewControllerDelegate {
    
    private let resolver: Resolver
	
	var interactor: SignInBusinessLogic?
	var router: (SignInRoutingLogic & SignInDataPassing)?

    private let mainView: SignInView = SignInView()
    
    weak var delegate: SignInViewControllerDelegate?

	//
	// MARK: - Object lifecycle
	//
	
    init(resolver: Resolver) {
        self.resolver = resolver
        
        super.init(nibName: nil, bundle: nil)
        
        self.setup(resolver: resolver)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
	//	
	// MARK: - Setup
	//
	
	private func setup(resolver: Resolver) {
		let viewController = self
        let interactor: SignInInteractor = resolver.resolve(SignInInteractor.self)!
		let presenter = SignInPresenter()
		let router = SignInRouter()
		viewController.interactor = interactor
		viewController.router = router
		interactor.presenter = presenter
		presenter.viewController = viewController
		router.viewController = viewController
		router.dataStore = interactor
	}
	
	//	
	// MARK: - View lifecycle
	//
    
    override func loadView() {
        self.mainView.delegate = self
        self.view = self.mainView
        self.view.frame = CGRect(x: 0, y: 0, width: CGSize.defaultWindow.width / 2, height: CGSize.defaultWindow.height / 2)
    }
	
	override func viewDidLoad() {
		super.viewDidLoad()

		self.initScene()
	}
	
	//	
	// MARK: - Init scene
	//
	
	private func initScene() {
		let request = SignIn.Init.Request()
		self.interactor?.initScene(request: request)
	}
	
	func displayInitialData(viewModel: SignIn.Init.ViewModel) {
        self.mainView.displayData(viewModel: viewModel)
	}
    
    //
    // MARK: - Sign in did begin
    //
    
    func displaySignInDidBegin() {
        self.mainView.displaySignInDidBegin()
    }
    
    //
    // MARK: - Sign in error
    //
    
    func displaySignInError(viewModel: SignIn.SignInError.ViewModel) {
        self.mainView.displaySignInError(viewModel: viewModel)
    }
    
    //
    // MARK: - Invalid field
    //
    
    func displayInvalidField(viewModel: SignIn.InvalidField.ViewModel) {
        self.mainView.displayInvalidField(viewModel: viewModel)
    }
    
    //
    // MARK: - Sign in complete
    //
    
    func displaySignInComplete() {
        self.delegate?.signInDidComplete(self)
    }
    
    //
    // MARK: - Two factor input
    //
    
    func displayTwoFactorInput() {
        self.router?.routeToTwoFactorInput()
    }
    
    //
    // MARK: - Sign in did cancel
    //
    
    func displaySignInDidCancel() {
        self.mainView.displaySignInDidCancel()
    }
    
    //
    // MARK: - View delegate
    //
    
    func signInButtonDidTap() {
        let request = SignIn.ProcessSignIn.Request(username: self.mainView.username, password: self.mainView.password)
        self.interactor?.signIn(request: request)
    }
    
    func signInCancelButtonDidTap() {
        // self.presentingViewController?.dismiss(self)
    }
    
    //
    // MARK: - Two factor input delegate
    //
    
    func twoFactorInputDidConfirm(_ scene: TwoFactorInputViewController, withCode code: String) {
        self.dismiss(scene)
        
        let request = SignIn.TwoFactorInput.Request(code: code)
        self.interactor?.processTwoFactorInput(request: request)
    }
    
    func twoFactorInputDidCancel(_ scene: TwoFactorInputViewController) {
        self.dismiss(scene)
        
        let request = SignIn.TwoFactorInput.Request(code: nil)
        self.interactor?.processTwoFactorInput(request: request)
    }
    
}
