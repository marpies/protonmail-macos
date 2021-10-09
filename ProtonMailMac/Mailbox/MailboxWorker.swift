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
    
    private var currentLabel: String?
    private var itemsBadgeObserver: NSObjectProtocol?

	weak var delegate: MailboxWorkerDelegate?
    
    init(resolver: Resolver) {
        self.resolver = resolver
        self.usersManager = resolver.resolve(UsersManager.self)!
        
        self.addObservers()
    }

	func loadData(request: Mailbox.Init.Request) {
        self.delegate?.mailboxDidLoad(response: Mailbox.Init.Response())
	}
    
    func loadTitle(request: Mailbox.LoadTitle.Request) {
        guard let label = self.getLabel(forId: request.labelId),
              let userId = self.usersManager.activeUser?.userId else { return }
        
        self.currentLabel = request.labelId
        
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
    
    private func addObservers() {
        self.itemsBadgeObserver = NotificationCenter.default.addObserver(forType: Mailbox.Notifications.ConversationCountsUpdate.self, object: nil, queue: .main, using: { [weak self] notification in
            guard let weakSelf = self, let notification = notification,
                  let userId = weakSelf.usersManager.activeUser?.userId,
                  userId == notification.userId,
                  let currentLabel = weakSelf.currentLabel else { return }
            
            var count: Int = -1
            
            for pair in notification.total {
                guard pair.key == currentLabel else { continue }
                
                count = pair.value
            }
            
            guard count >= 0, let label = weakSelf.getLabel(forId: currentLabel) else { return }
            
            let item: MailboxSidebar.Item = weakSelf.getSidebarItemKind(response: label)
            
            let response = Mailbox.LoadTitle.Response(item: item, numItems: count)
            weakSelf.delegate?.mailboxTitleDidLoad(response: response)
        })
    }

}
