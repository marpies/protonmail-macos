//
//  ConversationsRouter.swift
//  ProtonMailMac
//
//  Created by Marcel Piešťanský on 16.09.2021.
//  Copyright (c) 2021 marpies. All rights reserved.
//

import Foundation

protocol ConversationsRoutingLogic {
	func routeBack()
}

protocol ConversationsDataPassing {
	var dataStore: ConversationsDataStore? { get }
}

class ConversationsRouter: ConversationsRoutingLogic, ConversationsDataPassing {
	weak var viewController: ConversationsViewController?
	var dataStore: ConversationsDataStore?

	//
	// MARK: - Routing
	//
    
    func routeBack() {
        
    }
}
