//
//  MailboxSidebarWorker.swift
//  ProtonMailMac
//
//  Created by Marcel Piešťanský on 27.08.2021.
//  Copyright (c) 2021 marpies. All rights reserved.
//

import Foundation
import Swinject
import AppKit

protocol MailboxSidebarWorkerDelegate: AnyObject {
    func mailboxSidebarDidLoad(response: MailboxSidebar.Init.Response)
    func mailboxSidebarDidRefresh(response: MailboxSidebar.RefreshGroups.Response)
    func mailboxSidebarItemsBadgeDidUpdate(response: MailboxSidebar.ItemsBadgeUpdate.Response)
}

class MailboxSidebarWorker: LabelToSidebarItemParsing {

    private let resolver: Resolver
    private let usersManager: UsersManager
    private let keyValueStore: KeyValueStore
    private let db: LabelsDatabaseManaging
    
    private var labelId: String?
    private var itemsBadgeObserver: NSObjectProtocol?
    
	weak var delegate: MailboxSidebarWorkerDelegate?

    init(resolver: Resolver) {
        self.resolver = resolver
        self.usersManager = resolver.resolve(UsersManager.self)!
        self.keyValueStore = resolver.resolve(KeyValueStore.self)!
        self.db = self.resolver.resolve(LabelsDatabaseManaging.self)!
        
        self.addObservers()
    }

	func loadData(request: MailboxSidebar.Init.Request) {
        guard let user = self.usersManager.activeUser else {
            fatalError("Unexpected application state.")
        }
        
        let userId: String = user.userId
        
        // Set default selected label
        let defaultLabelId: String = self.keyValueStore.string(forKey: .lastLabelId) ?? MailboxSidebar.Item.inbox.id
        self.labelId = defaultLabelId
        
        // Load local cache
        self.db.fetchLabels(ofType: .all, forUser: userId) { labels in
            let groups = self.parseLabels(labels)
            
            // We have some cached labels, display those for now
            if !groups.isEmpty {
                let selectedRow = self.getSelectedLabelRow(groups: groups, labelId: defaultLabelId)
                let response = MailboxSidebar.Init.Response(groups: groups, selectedRow: selectedRow)
                self.delegate?.mailboxSidebarDidLoad(response: response)
                
                self.dispatchSidebarItems(groups: groups)
            }
            
            // Fetch labels from the server
            self.refreshLabels(user: user, cachedGroups: groups, defaultLabelId: defaultLabelId)
        }
	}
    
    func processSelectedItem(request: MailboxSidebar.ItemSelected.Request) {
        self.keyValueStore.setString(forKey: .lastLabelId, value: request.id)
    }
    
    //
    // MARK: - Private
    //
    
    private func refreshLabels(user: AuthUser, cachedGroups: [MailboxSidebar.Group.Response], defaultLabelId: String) {
        let userId: String = user.userId
        let request = LabelsRequest(type: .labels, authCredential: user.auth)
        let apiService: ApiService = self.resolver.resolve(ApiService.self)!
        
        apiService.request(request) { (response: LabelsResponse) in
            var labelsJSON: [[String: Any]] = response.labels ?? []
            
            // Error loading labels
            if labelsJSON.isEmpty || response.error != nil {
                // We have no cache, nothing to display
                if cachedGroups.isEmpty {
                    // todo handle error
                }
                return
            }
            
            // Add user ID to user labels
            for (index, _) in labelsJSON.enumerated() {
                labelsJSON[index]["UserID"] = userId
            }
            
            // Add built-in labels without user id
            labelsJSON.append(["ID": "0", "Order": 0]) // inbox   = "0"
            labelsJSON.append(["ID": "8", "Order": 1]) // draft   = "8"
            labelsJSON.append(["ID": "1", "Order": 2]) // draft   = "1"
            labelsJSON.append(["ID": "7", "Order": 3]) // sent    = "7"
            labelsJSON.append(["ID": "2", "Order": 4]) // sent    = "2"
            labelsJSON.append(["ID": "10", "Order": 5]) // starred = "10"
            labelsJSON.append(["ID": "6", "Order": 6]) // archive = "6"
            labelsJSON.append(["ID": "4", "Order": 7]) // spam    = "4"
            labelsJSON.append(["ID": "3", "Order": 8]) // trash   = "3"
            labelsJSON.append(["ID": "5", "Order": 9]) // allmail = "5"
            
            self.db.saveLabels(labelsJSON, forUser: userId) { savedLabels in
                let groups = self.parseLabels(savedLabels)
                
                self.updateCachedLabels(cachedGroups: cachedGroups, newGroups: groups)
                
                let selectedRow = self.getSelectedLabelRow(groups: groups, labelId: defaultLabelId)
                
                // No cached labels, init now
                if cachedGroups.isEmpty {
                    let response = MailboxSidebar.Init.Response(groups: groups, selectedRow: selectedRow)
                    self.delegate?.mailboxSidebarDidLoad(response: response)
                }
                // We had cached labels, refresh with the new ones
                else {
                    let response = MailboxSidebar.RefreshGroups.Response(groups: groups, selectedRow: selectedRow)
                    self.delegate?.mailboxSidebarDidRefresh(response: response)
                }
                
                self.dispatchSidebarItems(groups: groups)
            }
        }
    }
    
    private func updateCachedLabels(cachedGroups: [MailboxSidebar.Group.Response], newGroups: [MailboxSidebar.Group.Response]) {
        // Remove deleted labels from the database
        let deletedLabelIds: Set<String> = self.getDeletedLabels(cachedGroups: cachedGroups, newGroups: newGroups)
        if !deletedLabelIds.isEmpty {
            self.db.deleteLabelsById(deletedLabelIds, completion: nil)
        }
    }
    
    private func getDeletedLabels(cachedGroups: [MailboxSidebar.Group.Response], newGroups: [MailboxSidebar.Group.Response]) -> Set<String> {
        let cachedLabelIds: Set<String> = self.getLabelIds(fromGroups: cachedGroups)
        let newLabelIds: Set<String> = self.getLabelIds(fromGroups: newGroups)
        
        // Get all ids that are not part of the new label set
        return cachedLabelIds.filter { !newLabelIds.contains($0) }
    }
    
    private func getLabelIds(fromGroups groups: [MailboxSidebar.Group.Response]) -> Set<String> {
        var ids: Set<String> = []
        for group in groups {
            for label in group.labels {
                self.getLabelIds(fromItem: label, out: &ids)
            }
        }
        return ids
    }
    
    private func getLabelIds(fromItem item: MailboxSidebar.Item.Response, out: inout Set<String>) {
        out.insert(item.kind.id)
        
        if let children = item.children {
            for child in children {
                self.getLabelIds(fromItem: child, out: &out)
            }
        }
    }
    
    private func parseLabels(_ response: [Label]) -> [MailboxSidebar.Group.Response] {
        guard !response.isEmpty, let userId = self.usersManager.activeUser?.userId else { return [] }
        
        // Default ProtonMail inboxes
        var inboxes: [MailboxSidebar.Item.Response] = []
        
        // User's folders and labels
        var folders: [MailboxSidebar.Item.Response] = []
        var labels: [MailboxSidebar.Item.Response] = []
        
        var processedIds: Set<String> = []
        
        for label in response {
            let item: MailboxSidebar.Item.Response = self.getItem(response: label, userId: userId)
            
            // Skip duplicate default items (e.g. drafts, sent)
            if processedIds.contains(item.kind.id) { continue }
            
            processedIds.insert(item.kind.id)
            
            // No name -> default folder
            if label.name.isEmpty {
                inboxes.append(item)
            }
            // Custom folder
            else if label.exclusive {
                // Check parent
                if !label.parentID.isEmpty {
                    self.addToParentItem(item, parents: folders, parentId: label.parentID)
                } else {
                    folders.append(item)
                }
            }
            // Custom label
            else {
                labels.append(item)
            }
        }
        
        return [
            MailboxSidebar.Group.Response(kind: .inboxes, labels: inboxes),
            MailboxSidebar.Group.Response(kind: .folders, labels: folders),
            MailboxSidebar.Group.Response(kind: .labels, labels: labels)
        ]
    }
    
    private func getSelectedLabelRow(groups: [MailboxSidebar.Group.Response], labelId: String) -> Int {
        var row: Int = 0
        
        for group in groups {
            // Skip group title
            row += 1
            
            for label in group.labels {
                if label.kind.id == labelId {
                    return row
                }
                
                row += 1
            }
        }
        
        // Skip the first group title
        return 1
    }
    
    @discardableResult
    private func addToParentItem(_ item: MailboxSidebar.Item.Response, parents: [MailboxSidebar.Item.Response], parentId: String) -> Bool {
        for parent in parents {
            if parent.kind.id == parentId {
                parent.addChild(item)
                return true
            }
            
            if let children = parent.children, !children.isEmpty {
                let didAdd: Bool = self.addToParentItem(item, parents: children, parentId: parentId)
                if didAdd {
                    return true
                }
            }
        }
        
        return false
    }
    
    private func getItem(response: Label, userId: String) -> MailboxSidebar.Item.Response {
        var color: NSColor?
        if !response.color.isEmpty {
            color = NSColor(hexColorCode: response.color)
        }
        
        let kind: MailboxSidebar.Item = self.getSidebarItemKind(response: response)
        
        let db: LabelUpdateDatabaseManaging = self.resolver.resolve(LabelUpdateDatabaseManaging.self)!
        let numUnread: Int = db.unreadCount(for: response.labelID, userId: userId)
        
        return MailboxSidebar.Item.Response(kind: kind, color: color, numUnread: numUnread)
    }
    
    private func dispatchSidebarItems(groups: [MailboxSidebar.Group.Response]) {
        let notification: MailboxSidebar.Notifications.ItemsLoad = MailboxSidebar.Notifications.ItemsLoad(groups: groups)
        notification.post()
    }
    
    private func addObservers() {
        self.itemsBadgeObserver = NotificationCenter.default.addObserver(forType: Main.Notifications.ConversationCountsUpdate.self, object: nil, queue: .main, using: { [weak self] notification in
            guard let weakSelf = self, let notification = notification,
                  let userId = weakSelf.usersManager.activeUser?.userId,
                  userId == notification.userId else { return }
            
            let response = MailboxSidebar.ItemsBadgeUpdate.Response(items: notification.unread)
            weakSelf.delegate?.mailboxSidebarItemsBadgeDidUpdate(response: response)
        })
    }

}
