//
//  MessageDetailsRouter.swift
//  ProtonMailMac
//
//  Created by Marcel Piešťanský on 05.09.2021.
//  Copyright (c) 2021 marpies. All rights reserved.
//

import Foundation

protocol MessageDetailsRoutingLogic {
	func routeBack()
}

protocol MessageDetailsDataPassing {
	var dataStore: MessageDetailsDataStore? { get }
}

class MessageDetailsRouter: MessageDetailsRoutingLogic, MessageDetailsDataPassing {
	weak var viewController: MessageDetailsViewController?
	var dataStore: MessageDetailsDataStore?

	//
	// MARK: - Routing
	//
    
    func routeBack() {
        
    }
}
