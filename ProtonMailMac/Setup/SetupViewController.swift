//
//  SetupViewController.swift
//  ProtonMailMac
//
//  Created by Marcel Piešťanský on 24.08.2021.
//  Copyright (c) 2021 marpies. All rights reserved.
//

import AppKit
import SnapKit
import Swinject

protocol SetupDisplayLogic: AnyObject {
	func displayLaunchContent(viewModel: Setup.LaunchContent.ViewModel)
    func displaySignIn()
    func displayMailbox()
}

class SetupViewController: NSViewController, SetupDisplayLogic, SetupViewDelegate, SignInViewControllerDelegate {
	
	var interactor: SetupBusinessLogic?
	var router: (SetupRoutingLogic & SetupDataPassing)?

    private let mainView: SetupView = SetupView()

	//
	// MARK: - Object lifecycle
	//
	
    init(resolver: Resolver) {
		super.init(nibName: nil, bundle: nil)
		
		self.setup(resolver: resolver)
	}
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        print("SETUP VC Deinit")
    }
	
	//	
	// MARK: - Setup
	//
	
	private func setup(resolver: Resolver) {
		let viewController = self
        let interactor: SetupInteractor = resolver.resolve(SetupInteractor.self)!
		let presenter = SetupPresenter()
		let router = SetupRouter(resolver: resolver)
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
    }
	
	override func viewDidLoad() {
		super.viewDidLoad()

		self.initApp()
	}
	
	//	
	// MARK: - Init app
	//
	
	private func initApp() {
		let request = Setup.Init.Request()
		self.interactor?.initApp(request: request)
	}
	
    func displayLaunchContent(viewModel: Setup.LaunchContent.ViewModel) {
        self.mainView.displayLaunchContent(viewModel: viewModel)
	}
    
    //
    // MARK: - Display sign in
    //
    
    func displaySignIn() {
        self.router?.routeToSignIn()
    }
    
    //
    // MARK: - Display mailbox
    //
    
    func displayMailbox() {
        self.router?.routeToMailbox()
    }
    
    //
    // MARK: - Sign in view controller delegate
    //
    
    func signInDidComplete(_ scene: SignInViewController) {
        self.dismiss(scene)
        
        self.router?.routeToMailbox()
    }
    
}
