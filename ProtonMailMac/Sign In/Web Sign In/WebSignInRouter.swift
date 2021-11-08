//
//  WebSignInRouter.swift
//  ProtonMailMac
//
//  Created by Marcel Piešťanský on 04.11.2021.
//  Copyright (c) 2021 marpies. All rights reserved.
//

import Foundation

protocol WebSignInRoutingLogic {
	
}

protocol WebSignInDataPassing {
	var dataStore: WebSignInDataStore? { get }
}

class WebSignInRouter: WebSignInRoutingLogic, WebSignInDataPassing {
	weak var viewController: WebSignInViewController?
	var dataStore: WebSignInDataStore?

}
