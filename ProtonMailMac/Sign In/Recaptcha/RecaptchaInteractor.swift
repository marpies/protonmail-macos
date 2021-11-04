//
//  RecaptchaInteractor.swift
//  ProtonMailMac
//
//  Created by Marcel Piešťanský on 01.11.2021.
//  Copyright (c) 2021 marpies. All rights reserved.
//

import Foundation

protocol RecaptchaBusinessLogic {
	func loadData(request: Recaptcha.Init.Request)
}

protocol RecaptchaDataStore {
    var startToken: String? { get set }
}

class RecaptchaInteractor: RecaptchaBusinessLogic, RecaptchaDataStore, RecaptchaWorkerDelegate {

	var worker: RecaptchaWorker?

	var presenter: RecaptchaPresentationLogic?
    
    var startToken: String?
	
	//
	// MARK: - Load data
	//
	
	func loadData(request: Recaptcha.Init.Request) {
        self.worker?.startToken = self.startToken
		self.worker?.delegate = self
		self.worker?.loadData(request: request)
	}
    
    //
    // MARK: - Worker delegate
    //
    
    func captchaDidLoad(response: Recaptcha.Init.Response) {
        self.presenter?.presentData(response: response)
    }
    
}
