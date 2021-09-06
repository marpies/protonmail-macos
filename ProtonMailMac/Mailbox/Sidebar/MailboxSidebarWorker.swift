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
}

class MailboxSidebarWorker {

    private let resolver: Resolver
    private let usersManager: UsersManager
    
	weak var delegate: MailboxSidebarWorkerDelegate?

    init(resolver: Resolver) {
        self.resolver = resolver
        self.usersManager = resolver.resolve(UsersManager.self)!
    }

	func loadData(request: MailboxSidebar.Init.Request) {
        guard let user = self.usersManager.activeUser else {
            fatalError("Unexpected application state.")
        }
        
        let userId: String = user.userId
        let request = LabelsRequest(type: .labels, authCredential: user.auth)
        let apiService: ApiService = self.resolver.resolve(ApiService.self)!
        let db: LabelsDatabaseManaging = self.resolver.resolve(LabelsDatabaseManaging.self)!
        
        apiService.request(request) { (response: LabelsResponse) in
            var labelsJSON: [[String: Any]] = response.labels ?? []
            
            // Add user ID to user labels
            for (index, _) in labelsJSON.enumerated() {
                labelsJSON[index]["UserID"] = userId
            }
            
            // Add built-in labels without user id
            labelsJSON.append(["ID": "0"]) // inbox   = "0"
            labelsJSON.append(["ID": "8"]) // draft   = "8"
            labelsJSON.append(["ID": "1"]) // draft   = "1"
            labelsJSON.append(["ID": "7"]) // sent    = "7"
            labelsJSON.append(["ID": "2"]) // sent    = "2"
            labelsJSON.append(["ID": "10"]) // starred = "10"
            labelsJSON.append(["ID": "6"]) // archive = "6"
            labelsJSON.append(["ID": "4"]) // spam    = "4"
            labelsJSON.append(["ID": "3"]) // trash   = "3"
            labelsJSON.append(["ID": "5"]) // allmail = "5"
            
            db.saveLabels(labelsJSON, forUser: userId) {
                db.fetchLabels(ofType: .all, forUser: userId) { labels in
                    let groups = self.parseLabels(labels)
                    
                    self.delegate?.mailboxSidebarDidLoad(response: MailboxSidebar.Init.Response(groups: groups))
                }
            }
        }
	}
    
    //
    // MARK: - Private
    //
    
    private func parseLabels(_ response: [Label]) -> [MailboxSidebar.Group.Response] {
        // Default ProtonMail inboxes
        var inboxes: [MailboxSidebar.Item.Response] = []
        
        // User's folders and labels
        var folders: [MailboxSidebar.Item.Response] = []
        var labels: [MailboxSidebar.Item.Response] = []
        
        for label in response {
            let item: MailboxSidebar.Item.Response = self.getItem(response: label)
            
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
    
    private func getItem(response: Label) -> MailboxSidebar.Item.Response {
        var color: NSColor?
        if !response.color.isEmpty {
            color = NSColor(hexColorCode: response.color)
        }
        
        let kind: MailboxSidebar.Item = self.getItemKind(response: response)
        
        return MailboxSidebar.Item.Response(kind: kind, color: color)
    }
    
    private func getItemKind(response: Label) -> MailboxSidebar.Item {
        switch response.labelID {
        case "0":
            return .inbox
        case "1", "8":
            return .draft
        case "2", "7":
            return .outbox
        case "3":
            return .trash
        case "4":
            return .spam
        case "5":
            return .allMail
        case "6":
            return .archive
        case "10":
            return .starred
        default:
            return .custom(id: response.labelID, title: response.name, isFolder: response.exclusive)
        }
    }

}
