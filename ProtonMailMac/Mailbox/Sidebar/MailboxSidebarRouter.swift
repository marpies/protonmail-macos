//
//  MailboxSidebarRouter.swift
//  ProtonMailMac
//
//  Created by Marcel Piešťanský on 27.08.2021.
//  Copyright (c) 2021 marpies. All rights reserved.
//

import Foundation

protocol MailboxSidebarRoutingLogic {
	func routeBack()
}

protocol MailboxSidebarDataPassing {
	var dataStore: MailboxSidebarDataStore? { get }
}

class MailboxSidebarRouter: MailboxSidebarRoutingLogic, MailboxSidebarDataPassing {
	weak var viewController: MailboxSidebarViewController?
	var dataStore: MailboxSidebarDataStore?

	//
	// MARK: - Routing
	//
    
    func routeBack() {
        
    }
}
