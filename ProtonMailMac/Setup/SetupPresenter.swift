//
//  SetupPresenter.swift
//  ProtonMailMac
//
//  Created by Marcel Piešťanský on 24.08.2021.
//  Copyright (c) 2021 marpies. All rights reserved.
//

import AppKit

protocol SetupPresentationLogic {
    func presentLaunchContent()
    func presentSignIn()
    func presentMailbox()
}

class SetupPresenter: SetupPresentationLogic {
	weak var viewController: SetupDisplayLogic?

	//
	// MARK: - Present initial data
	//

    func presentLaunchContent() {
		let viewModel = Setup.LaunchContent.ViewModel()
		self.viewController?.displayLaunchContent(viewModel: viewModel)
	}
    
    //
    // MARK: - Present sign in
    //
    
    func presentSignIn() {
        self.viewController?.displaySignIn()
    }
    
    //
    // MARK: - Present mailbox
    //
    
    func presentMailbox() {
        self.viewController?.displayMailbox()
    }
    
}
