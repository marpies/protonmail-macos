//
//  MessageDetailsWorker.swift
//  ProtonMailMac
//
//  Created by Marcel Piešťanský on 05.09.2021.
//  Copyright (c) 2021 marpies. All rights reserved.
//

import Foundation
import Swinject

protocol MessageDetailsWorkerDelegate: AnyObject {
    func MessageDetailsDidLoad(response: MessageDetails.Init.Response)
}

class MessageDetailsWorker {

	private let resolver: Resolver

	weak var delegate: MessageDetailsWorkerDelegate?

	init(resolver: Resolver) {
		self.resolver = resolver
	}

	func loadData(request: MessageDetails.Init.Request) {
        
	}

}
