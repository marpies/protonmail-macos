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
    func mailboxTitleDidLoad(response: Mailbox.LoadTitle.Response)
}

class MailboxWorker: LabelToSidebarItemParsing {
    
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
    
    func loadTitle(request: Mailbox.LoadTitle.Request) {
        guard let label = self.getLabel(forId: request.labelId),
              let userId = self.usersManager.activeUser?.userId else { return }
        
        let item: MailboxSidebar.Item = self.getSidebarItemKind(response: label)
        
        let db: LabelUpdateDatabaseManaging = self.resolver.resolve(LabelUpdateDatabaseManaging.self)!
        let numItems: Int = db.getTotalCount(for: request.labelId, userId: userId)
        
        let response: Mailbox.LoadTitle.Response = Mailbox.LoadTitle.Response(item: item, numItems: numItems)
        self.delegate?.mailboxTitleDidLoad(response: response)
    }
    
    //
    // MARK: - Private
    //
    
    private func getLabel(forId id: String) -> Label? {
        let db: LabelsDatabaseManaging = self.resolver.resolve(LabelsDatabaseManaging.self)!
        
        return db.getLabel(byId: id)
    }

}
