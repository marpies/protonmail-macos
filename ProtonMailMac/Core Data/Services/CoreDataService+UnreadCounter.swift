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
    
    func notifyConversationCountsUpdate(userId: String) {
        self.backgroundContext.performWith { ctx in
            self.notifyConversationCountsUpdate(userId: userId, context: ctx)
        }
    }
    
    func notifyConversationCountsUpdate(userId: String, context: NSManagedObjectContext) {
        // Label id to number of conversations
        var unread: [String: Int] = [:]
        var total: [String: Int] = [:]
        
        let labels: [Label] = self.fetchLabels(ofType: .all, forUser: userId, withContext: context)
        for label in labels {
            if let update = self.lastUpdate(for: label.labelID, userId: userId, context: context) {
                let numUnread: Int = numericCast(update.unread)
                if numUnread > 0 {
                    unread[label.labelID] = numUnread
                }
                total[label.labelID] = numericCast(update.total)
            }
        }
        
        let notification: Main.Notifications.ConversationCountsUpdate = Main.Notifications.ConversationCountsUpdate(unread: unread, total: total, userId: userId)
        notification.post()
        
        // Update badge
        let badge: Int = self.unreadCount(for: MailboxSidebar.Item.allMail.id, userId: userId, context: context)
        self.setAppBadge(badge)
    }
    
}
