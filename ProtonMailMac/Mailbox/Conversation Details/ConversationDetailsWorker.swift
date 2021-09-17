//
//  ConversationDetailsWorker.swift
//  ProtonMailMac
//
//  Created by Marcel Piešťanský on 17.09.2021.
//  Copyright (c) 2021 marpies. All rights reserved.
//

import Foundation
import Swinject

protocol ConversationDetailsWorkerDelegate: AnyObject {
    func ConversationDetailsDidLoad(response: ConversationDetails.Init.Response)
}

class ConversationDetailsWorker {

	private let resolver: Resolver

	weak var delegate: ConversationDetailsWorkerDelegate?

	init(resolver: Resolver) {
		self.resolver = resolver
	}

	func loadData(request: ConversationDetails.Init.Request) {
        
	}

}
