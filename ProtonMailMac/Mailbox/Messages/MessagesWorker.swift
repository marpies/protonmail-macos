//
//  MessagesWorker.swift
//  ProtonMailMac
//
//  Created by Marcel Piešťanský on 05.09.2021.
//  Copyright (c) 2021 marpies. All rights reserved.
//

import Foundation
import Swinject

protocol MessagesWorkerDelegate: AnyObject {
    func MessagesDidLoad(response: Messages.Init.Response)
}

class MessagesWorker {

	private let resolver: Resolver

	weak var delegate: MessagesWorkerDelegate?

	init(resolver: Resolver) {
		self.resolver = resolver
	}

	func loadData(request: Messages.Init.Request) {
        
	}

}
