//
//  MainWorker.swift
//  ProtonMailMac
//
//  Created by Marcel Piešťanský on 25.08.2021.
//  Copyright (c) 2021 marpies. All rights reserved.
//

import Foundation
import Swinject

protocol MainWorkerDelegate: AnyObject {
    func mailboxDidLoad(response: Main.Init.Response)
    func mailboxTitleDidLoad(response: Main.LoadTitle.Response)
    func mailboxToolbarShouldUpdate(response: Main.UpdateToolbar.Response)
}

class MainWorker: LabelToSidebarItemParsing {
    
    private let resolver: Resolver
    private let usersManager: UsersManager
    
    private var currentLabel: String?
    private var itemsBadgeObserver: NSObjectProtocol?

	weak var delegate: MainWorkerDelegate?
    
    init(resolver: Resolver) {
        self.resolver = resolver
        self.usersManager = resolver.resolve(UsersManager.self)!
        
        self.addObservers()
    }

	func loadData(request: Main.Init.Request) {
        self.delegate?.mailboxDidLoad(response: Main.Init.Response())
	}
    
    func loadTitle(request: Main.LoadTitle.Request) {
        guard let label = self.getLabel(forId: request.labelId),
              let userId = self.usersManager.activeUser?.userId else { return }
        
        self.currentLabel = request.labelId
        
        let item: MailboxSidebar.Item = self.getSidebarItemKind(response: label)
        
        let db: LabelUpdateDatabaseManaging = self.resolver.resolve(LabelUpdateDatabaseManaging.self)!
        let numItems: Int = db.getTotalCount(for: request.labelId, userId: userId)
        
        let response: Main.LoadTitle.Response = Main.LoadTitle.Response(item: item, numItems: numItems)
        self.delegate?.mailboxTitleDidLoad(response: response)
    }
    
    func processMailboxSelectionUpdate(request: Main.MailboxSelectionDidUpdate.Request) {
        let isSelectionActive: Bool
        let isMultiSelection: Bool
        
        switch request.type {
        case .none:
            isSelectionActive = false
            isMultiSelection = false
        case .messages(let ids):
            isSelectionActive = true
            isMultiSelection = ids.count > 1
        case .conversations(let ids):
            isSelectionActive = true
            isMultiSelection = ids.count > 1
        }
        
        let response: Main.UpdateToolbar.Response = Main.UpdateToolbar.Response(isSelectionActive: isSelectionActive, isMultiSelection: isMultiSelection)
        self.delegate?.mailboxToolbarShouldUpdate(response: response)
    }
    
    func processSceneDidInitialize() {
        let response: Main.UpdateToolbar.Response = Main.UpdateToolbar.Response(isSelectionActive: false, isMultiSelection: false)
        self.delegate?.mailboxToolbarShouldUpdate(response: response)
    }
    
    func processToolbarAction(request: Main.ToolbarAction.Request) {
        let notification: Main.Notifications.ToolbarAction = Main.Notifications.ToolbarAction(itemId: request.id)
        notification.post()
    }
    
    //
    // MARK: - Private
    //
    
    private func getLabel(forId id: String) -> Label? {
        let db: LabelsDatabaseManaging = self.resolver.resolve(LabelsDatabaseManaging.self)!
        
        return db.getLabel(byId: id)
    }
    
    private func addObservers() {
        self.itemsBadgeObserver = NotificationCenter.default.addObserver(forType: Main.Notifications.ConversationCountsUpdate.self, object: nil, queue: .main, using: { [weak self] notification in
            guard let weakSelf = self, let notification = notification,
                  let userId = weakSelf.usersManager.activeUser?.userId,
                  userId == notification.userId,
                  let currentLabel = weakSelf.currentLabel else { return }
            
            var count: Int = -1
            
            for pair in notification.total {
                guard pair.key == currentLabel else { continue }
                
                count = pair.value
                break
            }
            
            guard count >= 0, let label = weakSelf.getLabel(forId: currentLabel) else { return }
            
            let item: MailboxSidebar.Item = weakSelf.getSidebarItemKind(response: label)
            
            let response = Main.LoadTitle.Response(item: item, numItems: count)
            weakSelf.delegate?.mailboxTitleDidLoad(response: response)
        })
    }

}
