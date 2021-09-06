//
//  MailboxWorker.swift
//  ProtonMailMac
//
//  Created by Marcel Piešťanský on 25.08.2021.
//  Copyright (c) 2021 marpies. All rights reserved.
//

import Foundation
import Swinject

protocol MailboxWorkerDelegate: AnyObject {
    func mailboxDidLoad(response: Mailbox.Init.Response)
}

class MailboxWorker {
    
    private let resolver: Resolver
    private let usersManager: UsersManager

	weak var delegate: MailboxWorkerDelegate?
    
    init(resolver: Resolver) {
        self.resolver = resolver
        self.usersManager = resolver.resolve(UsersManager.self)!
    }

	func loadData(request: Mailbox.Init.Request) {
        self.delegate?.mailboxDidLoad(response: Mailbox.Init.Response())
	}

}
