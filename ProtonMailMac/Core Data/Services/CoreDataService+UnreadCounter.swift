//
//  CoreDataService+UnreadCounter.swift
//  ProtonMailMac
//
//  Created by Marcel Piešťanský on 08.10.2021.
//  Copyright © 2021 marpies. All rights reserved.
//

import Foundation
import CoreData

extension CoreDataService {
    
    func notifyUnreadCountersUpdate(userId: String) {
        self.backgroundContext.performWith { ctx in
            self.notifyUnreadCountersUpdate(userId: userId, context: ctx)
        }
    }
    
    func notifyUnreadCountersUpdate(userId: String, context: NSManagedObjectContext) {
        // Label id to badge number
        var items: [String: Int] = [:]
        
        let labels: [Label] = self.fetchLabels(ofType: .all, forUser: userId, withContext: context)
        for label in labels {
            let numUnread: Int = self.unreadCount(for: label.labelID, userId: userId, context: context)
            if numUnread > 0 {
                items[label.labelID] = numUnread
            }
        }
        
        let notification: MailboxSidebar.Notifications.ItemsBadgeUpdate = MailboxSidebar.Notifications.ItemsBadgeUpdate(items: items, userId: userId)
        notification.post()
        
        // Update badge
        let badge: Int = self.unreadCount(for: MailboxSidebar.Item.allMail.id, userId: userId, context: context)
        self.setAppBadge(badge)
    }
    
}
