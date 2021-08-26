//
//  MailboxWorker.swift
//  ProtonMailMac
//
//  Created by Marcel Piešťanský on 25.08.2021.
//  Copyright (c) 2021 marpies. All rights reserved.
//

import Foundation

protocol MailboxWorkerDelegate: AnyObject {
    func mailboxDidLoad(response: Mailbox.Init.Response)
}

class MailboxWorker {

	weak var delegate: MailboxWorkerDelegate?

	func loadData(request: Mailbox.Init.Request) {
        self.delegate?.mailboxDidLoad(response: Mailbox.Init.Response())
	}

}
