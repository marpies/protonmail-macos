//
//  ConversationDetailsRouter.swift
//  ProtonMailMac
//
//  Created by Marcel Piešťanský on 17.09.2021.
//  Copyright (c) 2021 marpies. All rights reserved.
//

import Foundation

protocol ConversationDetailsRoutingLogic {
	func routeBack()
}

protocol ConversationDetailsDataPassing {
	var dataStore: ConversationDetailsDataStore? { get }
}

class ConversationDetailsRouter: ConversationDetailsRoutingLogic, ConversationDetailsDataPassing {
	weak var viewController: ConversationDetailsViewController?
	var dataStore: ConversationDetailsDataStore?

	//
	// MARK: - Routing
	//
    
    func routeBack() {
        
    }
}
