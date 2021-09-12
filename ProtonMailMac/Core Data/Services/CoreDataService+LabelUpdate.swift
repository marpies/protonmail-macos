//
//  CoreDataService+LabelUpdate.swift
//  ProtonMailMac
//
//  Copyright (c) 2019 Proton Technologies AG
//
//  This file is part of ProtonMail.
//
//  ProtonMail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ProtonMail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonMail.  If not, see <https://www.gnu.org/licenses/>.

import Foundation
import CoreData
import PromiseKit

extension CoreDataService: LabelUpdateDatabaseManaging {
    
    func lastUpdate(for labelId : String, userId: String) -> LabelUpdate? {
        //TODO:: fix me fetch everytime is expensive
        let context: NSManagedObjectContext = self.mainContext
        return self.lastUpdate(for: labelId, userId: userId, context: context)
    }
    
    func lastUpdateDefault(for labelId : String, userId: String) -> LabelUpdate {
        let context: NSManagedObjectContext = self.mainContext
        if let update = self.lastUpdate(for: labelId, userId: userId, context: context) {
            return update
        }
        return LabelUpdate.newLabelUpdate(by: labelId, userID: userId, inManagedObjectContext: context)
    }
    
    // location & label: message unread count
    func unreadCount(for labelId : String, userId: String) -> Promise<Int> {
        return Promise { seal in
            let context: NSManagedObjectContext = self.mainContext
            self.enqueue(context: context) { (ctx) in
                let update = self.lastUpdate(for: labelId, userId: userId, context: ctx)
                
                guard let result = update?.unread else {
                    seal.fulfill(0)
                    return
                }
                
                seal.fulfill(Int(result))
            }
        }
    }
    
    func unreadCount(for labelId : String, userId: String) -> Int {
        var unreadCount: Int32?
        let update = self.lastUpdate(for: labelId, userId: userId)
        unreadCount = update?.unread
        
        guard let result = unreadCount else {
            return 0
        }
        return Int(result)
    }
    
    
    // update unread count
    func updateUnreadCount(for labelId : String, userId: String, count: Int, shouldSave: Bool) {
        let update = self.lastUpdateDefault(for: labelId, userId: userId)
        update.unread = Int32(count)
        
        let context: NSManagedObjectContext = self.mainContext
        
        if shouldSave {
            let _ = context.saveUpstreamIfNeeded()
        }
        
        // Set app badge
        if labelId == MailboxSidebar.Item.inbox.id {
            self.setAppBadge(count)
        }
    }
    
    func removeUpdateTime(forUser userId: String) {
        let context: NSManagedObjectContext = self.mainContext
        self.enqueue(context: context) { (context) in
            let _ = LabelUpdate.remove(by: userId, inManagedObjectContext: context)
        }
    }
    
    //
    // MARK: - Private
    //
    
    private func lastUpdate(for labelId : String, userId: String, context: NSManagedObjectContext) -> LabelUpdate? {
        return LabelUpdate.lastUpdate(by: labelId, userID: userId, inManagedObjectContext: context)
    }
    
}
