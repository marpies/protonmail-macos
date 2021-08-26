//
//  SetupRouter.swift
//  ProtonMailMac
//
//  Created by Marcel Piešťanský on 24.08.2021.
//  Copyright (c) 2021 marpies. All rights reserved.
//

import Foundation
import Swinject

protocol SetupRoutingLogic {
    func routeToSignIn()
	func routeToMailbox()
}

protocol SetupDataPassing {
	var dataStore: SetupDataStore? { get }
}

class SetupRouter: SetupRoutingLogic, SetupDataPassing {
    private let resolver: Resolver
    
	weak var viewController: SetupViewController?
	var dataStore: SetupDataStore?
    
    init(resolver: Resolver) {
        self.resolver = resolver
    }

	//
	// MARK: - Routing
	//
    
    func routeToSignIn() {
        let destinationVC: SignInViewController = self.resolver.resolve(SignInViewController.self)!
        destinationVC.delegate = self.viewController
        self.viewController?.presentAsSheet(destinationVC)
    }
    
    func routeToMailbox() {
        if let app = self.viewController?.parent as? AppViewController {
            let destinationVC = MailboxViewController()
            app.displaySection(destinationVC)
        }
    }
}
