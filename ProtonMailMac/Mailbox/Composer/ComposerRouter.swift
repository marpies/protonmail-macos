//
//  ComposerRouter.swift
//  ProtonMailMac
//
//  Created by Marcel Piešťanský on 26.11.2021.
//  Copyright (c) 2021 marpies. All rights reserved.
//

import Foundation

protocol ComposerRoutingLogic {
	func routeBack()
}

protocol ComposerDataPassing {
	var dataStore: ComposerDataStore? { get }
}

class ComposerRouter: ComposerRoutingLogic, ComposerDataPassing {
	weak var viewController: ComposerViewController?
	var dataStore: ComposerDataStore?

	//
	// MARK: - Routing
	//
    
    func routeBack() {
        
    }
}
