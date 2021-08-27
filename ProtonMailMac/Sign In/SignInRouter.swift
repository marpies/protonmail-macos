//
//  SignInRouter.swift
//  ProtonMailMac
//
//  Created by Marcel Piešťanský on 25.08.2021.
//  Copyright (c) 2021 marpies. All rights reserved.
//

import Foundation

protocol SignInRoutingLogic {
	func routeBack()
    func routeToTwoFactorInput()
}

protocol SignInDataPassing {
	var dataStore: SignInDataStore? { get }
}

class SignInRouter: SignInRoutingLogic, SignInDataPassing {
	weak var viewController: SignInViewController?
	var dataStore: SignInDataStore?

	//
	// MARK: - Routing
	//
    
    func routeBack() {
        
    }
    
    func routeToTwoFactorInput() {
        let destinationVC = TwoFactorInputViewController()
        destinationVC.delegate = self.viewController
        self.viewController?.presentAsSheet(destinationVC)
    }
}
