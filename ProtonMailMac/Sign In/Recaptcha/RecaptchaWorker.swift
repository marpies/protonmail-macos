//
//  RecaptchaWorker.swift
//  ProtonMailMac
//
//  Created by Marcel Piešťanský on 01.11.2021.
//  Copyright (c) 2021 marpies. All rights reserved.
//

import Foundation
import Swinject

protocol RecaptchaWorkerDelegate: AnyObject {
    func captchaDidLoad(response: Recaptcha.Init.Response)
}

class RecaptchaWorker {

	private let resolver: Resolver
    
    var startToken: String?

	weak var delegate: RecaptchaWorkerDelegate?

	init(resolver: Resolver) {
		self.resolver = resolver
	}

	func loadData(request: Recaptcha.Init.Request) {
        guard let url = self.getUrl() else {
            fatalError("Unexpected application state.")
        }
        
        URLCache.shared.removeAllCachedResponses()
        
        let response: Recaptcha.Init.Response = Recaptcha.Init.Response(url: url)
        self.delegate?.captchaDidLoad(response: response)
	}
    
    //
    // MARK: - Private
    //
    
    private func getUrl() -> URLRequest? {
        guard let token = self.startToken else { return nil }
        
        let urlRaw: String = "https://account-api.protonmail.com/core/v4/captcha?Token=\(token)"
        
        guard let url = URL(string: urlRaw) else { return nil }
        
        return URLRequest(url: url)
    }

}
