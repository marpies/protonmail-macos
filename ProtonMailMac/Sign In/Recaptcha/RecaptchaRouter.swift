//
//  RecaptchaRouter.swift
//  ProtonMailMac
//
//  Created by Marcel Piešťanský on 01.11.2021.
//  Copyright (c) 2021 marpies. All rights reserved.
//

import Foundation

protocol RecaptchaRoutingLogic {
    
}

protocol RecaptchaDataPassing {
	var dataStore: RecaptchaDataStore? { get }
}

class RecaptchaRouter: RecaptchaRoutingLogic, RecaptchaDataPassing {
	weak var viewController: RecaptchaViewController?
	var dataStore: RecaptchaDataStore?
    
}
