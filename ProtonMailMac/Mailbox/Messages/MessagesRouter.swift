//
//  MessagesRouter.swift
//  ProtonMailMac
//
//  Created by Marcel Piešťanský on 05.09.2021.
//  Copyright (c) 2021 marpies. All rights reserved.
//

import Foundation

protocol MessagesRoutingLogic {
	func routeBack()
}

protocol MessagesDataPassing {
	var dataStore: MessagesDataStore? { get }
}

class MessagesRouter: MessagesRoutingLogic, MessagesDataPassing {
	weak var viewController: MessagesViewController?
	var dataStore: MessagesDataStore?

	//
	// MARK: - Routing
	//
    
    func routeBack() {
        
    }
}
