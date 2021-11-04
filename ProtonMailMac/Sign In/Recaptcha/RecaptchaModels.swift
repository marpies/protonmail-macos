//
//  RecaptchaModels.swift
//  ProtonMailMac
//
//  Created by Marcel Piešťanský on 01.11.2021.
//  Copyright (c) 2021 marpies. All rights reserved.
//

import Foundation

enum Recaptcha {

	//
	// MARK: - Init
	//

	enum Init {
		struct Request {
		}

		struct Response {
            let url: URLRequest
		}

		struct ViewModel {
            let url: URLRequest
            let closeIcon: String
		}
	}
    
}
