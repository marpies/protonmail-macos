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
    private var sidebarItemsObserver: NSObjectProtocol?
    private var messageUpdateObserver: NSObjectProtocol?
    private var messagesUpdateObserver: NSObjectProtocol?
    private var conversationUpdateObserver: NSObjectProtocol?
    private var conversationsUpdateObserver: NSObjectProtocol?
    
    private var mailboxSelectionType: Mailbox.SelectionType = .none
    
    /// Label items for the toolbar.
    private var labelItems: [MailboxSidebar.Item.Response]?
    
    /// Folder items for the toolbar.
    private var folderItems: [MailboxSidebar.Item.Response]?

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
        self.mailboxSelectionType = request.type
        
        self.updateToolbarMenuItems()
    }
    
    func processSceneDidInitialize() {
        let response: Main.UpdateToolbar.Response = Main.UpdateToolbar.Response(isSelectionActive: false, isMultiSelection: false, labelItems: nil, folderItems: nil)
        self.delegate?.mailboxToolbarShouldUpdate(response: response)
    }
    
    func processToolbarAction(request: Main.ToolbarAction.Request) {
        let notification: Main.Notifications.ToolbarAction = Main.Notifications.ToolbarAction(itemId: request.id)
        notification.post()
    }
    
    func processToolbarMenuItemTap(request: Main.ToolbarMenuItemTap.Request) {
        let itemId: String
        
        switch request.id {
        case .updateLabel(let labelId):
            itemId = labelId
            
        default:
            return
        }
        
        guard let label = self.getLabel(forId: itemId) else { return }
        
        let isLabel: Bool = Int(itemId) == nil && !label.exclusive
        let action: Main.ToolbarItem.Menu.Item.Action
        
        // Check if a label is to be added or removed based on the menu item's state
        if isLabel {
            switch request.state {
            case .on, .mixed:
                // Remove label
                action = .updateLabel(labelId: itemId, apply: false)
                
            case .off:
                // Add label
                action = .updateLabel(labelId: itemId, apply: true)
                
            default:
                return
            }
        }
        // Move to a folder
        else {
            action = .moveToFolder(folderId: itemId)
        }
        
        // Post notification to handle the action
        let notification: Main.Notifications.ToolbarMenuItemAction = Main.Notifications.ToolbarMenuItemAction(action: action)
        notification.post()
    }
    
    //
    // MARK: - Private
    //
    
    private func updateToolbarMenuItems(updatedIds: Set<String>) {
        // Check if we have any of the updated conversations/messages selected
        // and if so, update the toolbar menu items to reflect potential changes in the labels
        switch self.mailboxSelectionType {
        case .none:
            // Nothing to do
            return
        case .messages(let ids):
            let selectedHasChanged: Bool = ids.contains(where: { updatedIds.contains($0) })
            if !selectedHasChanged {
                return
            }
            
        case .conversations(let ids):
            let selectedHasChanged: Bool = ids.contains(where: { updatedIds.contains($0) })
            if !selectedHasChanged {
                return
            }
        }
        
        // Change occurred to the selected items, update the toolbar items
        self.updateToolbarMenuItems()
    }
    
    private func updateToolbarMenuItems() {
        switch self.mailboxSelectionType {
        case .none:
            // Nothing to do
            return
        case .messages(let ids):
            if let labels = self.labelItems {
                let labelIds: [String] = labels.map { $0.kind.id }
                let db: MessagesDatabaseManaging = self.resolver.resolve(MessagesDatabaseManaging.self)!
                db.loadLabelStatus(messageIds: ids, labelIds: labelIds) { state in
                    self.updateToolbarMenuItems(labels: labels, folders: self.folderItems, state: state)
                }
            } else {
                self.updateToolbarMenuItems(labels: self.labelItems, folders: self.folderItems, state: nil)
            }
        case .conversations(let ids):
            if let labels = self.labelItems {
                let labelIds: [String] = labels.map { $0.kind.id }
                let db: ConversationsDatabaseManaging = self.resolver.resolve(ConversationsDatabaseManaging.self)!
                db.loadLabelStatus(conversationIds: ids, labelIds: labelIds) { state in
                    self.updateToolbarMenuItems(labels: labels, folders: self.folderItems, state: state)
                }
            } else {
                self.updateToolbarMenuItems(labels: self.labelItems, folders: self.folderItems, state: nil)
            }
        }
    }
    
    private func updateToolbarMenuItems(labels: [MailboxSidebar.Item.Response]?, folders: [MailboxSidebar.Item.Response]?, state: [String: Main.ToolbarItem.Menu.Item.StateValue]?) {
        let isSelectionActive: Bool
        let isMultiSelection: Bool
        
        switch self.mailboxSelectionType {
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
        
        // Label items
        let labelItems: [Main.ToolbarItem.Menu.Item]? = labels?.map { item in
            .item(model: item, state: state?[item.kind.id])
        }
        
        // Folder items (default + custom)
        var folderItems: [Main.ToolbarItem.Menu.Item]?
        if let folders = folders {
            folderItems = []
            
            // Add separator between default and custom folders
            var didAddSeparator: Bool = false
            
            for folder in folders {
                // When the first custom folder is encountered, add separator
                if !didAddSeparator, case MailboxSidebar.Item.custom(_, _, _) = folder.kind {
                    didAddSeparator = true
                    folderItems?.append(.separator)
                }
                
                folderItems?.append(.item(model: folder, state: state?[folder.kind.id]))
            }
        }
        
        let response: Main.UpdateToolbar.Response = Main.UpdateToolbar.Response(isSelectionActive: isSelectionActive, isMultiSelection: isMultiSelection, labelItems: labelItems, folderItems: folderItems)
        self.delegate?.mailboxToolbarShouldUpdate(response: response)
    }
    
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
        
        // Listen to sidebar items load to update items in the toolbar menu (i.e. labels and folders)
        self.sidebarItemsObserver = NotificationCenter.default.addObserver(forType: MailboxSidebar.Notifications.ItemsLoad.self, object: nil, queue: .main, using: { [weak self] notification in
            guard let weakSelf = self, let groups = notification?.groups else { return }
            
            weakSelf.processSidebarItemsUpdate(groups: groups)
        })
        
        // Listen to conversation/message updates to refresh toolbar menu items if needed
        self.messageUpdateObserver = NotificationCenter.default.addObserver(forType: Messages.Notifications.MessageUpdate.self, object: nil, queue: .main, using: { [weak self] notification in
            guard let weakSelf = self, let messageId = notification?.messageId else { return }
            
            weakSelf.updateToolbarMenuItems(updatedIds: [messageId])
        })
        
        self.messagesUpdateObserver = NotificationCenter.default.addObserver(forType: Messages.Notifications.MessagesUpdate.self, object: nil, queue: .main, using: { [weak self] notification in
            guard let weakSelf = self, let messageIds = notification?.messageIds else { return }
            
            weakSelf.updateToolbarMenuItems(updatedIds: messageIds)
        })
        
        self.conversationUpdateObserver = NotificationCenter.default.addObserver(forType: Conversations.Notifications.ConversationUpdate.self, object: nil, queue: .main, using: { [weak self] notification in
            guard let weakSelf = self, let conversationId = notification?.conversationId else { return }
            
            weakSelf.updateToolbarMenuItems(updatedIds: [conversationId])
        })
        
        self.conversationsUpdateObserver = NotificationCenter.default.addObserver(forType: Conversations.Notifications.ConversationsUpdate.self, object: nil, queue: .main, using: { [weak self] notification in
            guard let weakSelf = self, let conversationIds = notification?.conversationIds else { return }
            
            weakSelf.updateToolbarMenuItems(updatedIds: conversationIds)
        })
    }
    
    private func processSidebarItemsUpdate(groups: [MailboxSidebar.Group.Response]) {
        // Get folders
        self.folderItems = self.getSidebarItems(groups: groups, folder: true)
        
        // Get labels
        self.labelItems = self.getSidebarItems(groups: groups, folder: false)
        
        self.updateToolbarMenuItems()
    }
    
    private func getSidebarItems(groups: [MailboxSidebar.Group.Response], folder: Bool) -> [MailboxSidebar.Item.Response] {
        var result: [MailboxSidebar.Item.Response] = []
        
        for group in groups {
            for item in group.labels {
                switch item.kind {
                case .custom(_, _, let isFolder):
                    guard isFolder == folder else { continue }
                    
                    result.append(item)
                    
                case .inbox, .trash, .archive, .spam:
                    guard folder else { continue }
                    
                    result.append(item)
                    
                default:
                    break
                }
            }
        }
        
        return result
    }
    
    private func getLabelItem(id: String) -> MailboxSidebar.Item.Response? {
        if let label = self.labelItems?.first(where: { $0.kind.id == id }) {
            return label
        }
        if let folder = self.folderItems?.first(where: { $0.kind.id == id }) {
            return folder
        }
        return nil
    }

}
