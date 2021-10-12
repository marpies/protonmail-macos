//
//  MainRouter.swift
//  ProtonMailMac
//
//  Created by Marcel Piešťanský on 25.08.2021.
//  Copyright (c) 2021 marpies. All rights reserved.
//

import Foundation

protocol MainRoutingLogic {
	func routeBack()
}

protocol MainDataPassing {
	var dataStore: MainDataStore? { get }
}

class MainRouter: MainRoutingLogic, MainDataPassing {
	weak var viewController: MainViewController?
	var dataStore: MainDataStore?

	//
	// MARK: - Routing
	//
    
    func routeBack() {
        
    }
}
