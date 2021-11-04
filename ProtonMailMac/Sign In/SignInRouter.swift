//
//  SignInRouter.swift
//  ProtonMailMac
//
//  Created by Marcel Piešťanský on 25.08.2021.
//  Copyright (c) 2021 marpies. All rights reserved.
//

import Foundation
import Swinject

protocol SignInRoutingLogic {
	func routeBack()
    func routeToTwoFactorInput()
    func routeToCaptcha()
}

protocol SignInDataPassing {
	var dataStore: SignInDataStore? { get }
}

class SignInRouter: SignInRoutingLogic, SignInDataPassing {
	weak var viewController: SignInViewController?
	var dataStore: SignInDataStore?
    
    private let resolver: Resolver

    init(resolver: Resolver) {
        self.resolver = resolver
    }

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
    
    func routeToCaptcha() {
        let destinationVC: RecaptchaViewController = self.resolver.resolve(RecaptchaViewController.self)!
        destinationVC.delegate = self.viewController
        var destinationDS = destinationVC.router!.dataStore!
        destinationDS.startToken = self.dataStore?.captchaStartToken
        self.viewController?.presentAsSheet(destinationVC)
    }
}
