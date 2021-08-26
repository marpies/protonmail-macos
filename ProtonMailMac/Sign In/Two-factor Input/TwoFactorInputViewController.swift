//
//  TwoFactorInputViewController.swift
//  ProtonMailMac
//
//  Created by Marcel Piešťanský on 26.08.2021.
//  Copyright (c) 2021 marpies. All rights reserved.
//

import AppKit

protocol TwoFactorInputDisplayLogic: AnyObject {
	func displayInitialData(viewModel: TwoFactorInput.Init.ViewModel)
    func displayInvalidField(viewModel: TwoFactorInput.InvalidField.ViewModel)
    func displaySceneDismissal()
}

protocol TwoFactorInputViewControllerDelegate: AnyObject {
    func twoFactorInputDidConfirm(_ scene: TwoFactorInputViewController, withCode code: String)
    func twoFactorInputDidCancel(_ scene: TwoFactorInputViewController)
}

class TwoFactorInputViewController: NSViewController, TwoFactorInputDisplayLogic, TwoFactorInputViewDelegate {
	
	var interactor: TwoFactorInputBusinessLogic?
    
    weak var delegate: TwoFactorInputViewControllerDelegate?

    private let mainView: TwoFactorInputView = TwoFactorInputView()

	//
	// MARK: - Object lifecycle
	//
	
	override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
		super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
		
		self.setup()
	}
	
	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		
		self.setup()
	}
	
	//	
	// MARK: - Setup
	//
	
	private func setup() {
		let viewController = self
		let interactor = TwoFactorInputInteractor()
		let presenter = TwoFactorInputPresenter()
		viewController.interactor = interactor
		interactor.presenter = presenter
		presenter.viewController = viewController
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

		self.loadInitialData()
	}
	
	//	
	// MARK: - Load data
	//
	
	private func loadInitialData() {
		let request = TwoFactorInput.Init.Request()
		self.interactor?.loadInitialData(request: request)
	}
	
    func displayInitialData(viewModel: TwoFactorInput.Init.ViewModel) {
        self.mainView.displayData(viewModel: viewModel)
	}
    
    //
    // MARK: - Invalid field
    //
    
    func displayInvalidField(viewModel: TwoFactorInput.InvalidField.ViewModel) {
        self.mainView.displayInvalidField(viewModel: viewModel)
    }
    
    //
    // MARK: - Scene dismissal
    //
    
    func displaySceneDismissal() {
        self.delegate?.twoFactorInputDidConfirm(self, withCode: self.mainView.inputCode)
    }
    
    //
    // MARK: - View delegate
    //
    
    func twoFactorConfirmButtonDidTap() {
        let request = TwoFactorInput.ProcessInput.Request(input: self.mainView.inputCode)
        self.interactor?.processInput(request: request)
    }
    
    func twoFactorCancelButtonDidTap() {
        self.delegate?.twoFactorInputDidCancel(self)
    }
}
