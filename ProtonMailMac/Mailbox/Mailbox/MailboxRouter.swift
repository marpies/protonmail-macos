//
//  MailboxRouter.swift
//  ProtonMailMac
//
//  Created by Marcel Piešťanský on 16.09.2021.
//  Copyright (c) 2021 marpies. All rights reserved.
//

import Foundation

protocol MailboxRoutingLogic {
	func routeBack()
}

protocol MailboxDataPassing {
	var dataStore: MailboxDataStore? { get }
}

class MailboxRouter: MailboxRoutingLogic, MailboxDataPassing {
	weak var viewController: MailboxViewController?
	var dataStore: MailboxDataStore?

	//
	// MARK: - Routing
	//
    
    func routeBack() {
        
    }
}
