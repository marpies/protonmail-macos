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
        let context: NSManagedObjectContext = self.mainContext
        self.updateUnreadCount(for: labelId, userId: userId, count: count, context: context)
        
        if shouldSave {
            let error = context.saveUpstreamIfNeeded()
            if error == nil {
                // Set app badge
                if labelId == MailboxSidebar.Item.allMail.id {
                    self.setAppBadge(count)
                }
            }
        }
    }
    
    func updateCount(for labelId: String, userId: String, unread: Int, total: Int, shouldSave: Bool) {
        self.updateCount(for: labelId, userId: userId, unread: unread, total: total, shouldSave: shouldSave, context: self.mainContext)
    }
    
    func removeUpdateTime(forUser userId: String) {
        let context: NSManagedObjectContext = self.mainContext
        self.enqueue(context: context) { (context) in
            let _ = LabelUpdate.remove(by: userId, inManagedObjectContext: context)
        }
    }
    
    //
    // MARK: - Internal
    //
    
    func updateUnreadCount(for labelId: String, userId: String, count: Int, context: NSManagedObjectContext) {
        let update = self.lastUpdateDefault(for: labelId, userId: userId, context: context)
        update.unread = Int32(count)
    }
    
    func unreadCount(for labelId: String, userId: String, context: NSManagedObjectContext) -> Int {
        var unreadCount: Int32?
        let update = self.lastUpdate(for: labelId, userId: userId, context: context)
        
        unreadCount = update?.unread
        
        guard let result = unreadCount else {
            return 0
        }
        
        return Int(result)
    }
    
    func lastUpdateDefault(for labelId: String, userId: String, context: NSManagedObjectContext) -> LabelUpdate {
        if let update = self.lastUpdate(for: labelId, userId: userId, context: context) {
            return update
        }
        return LabelUpdate.newLabelUpdate(by: labelId, userID: userId, inManagedObjectContext: context)
    }
    
    func updateCount(for labelId: String, userId: String, unread: Int, total: Int, shouldSave: Bool, context: NSManagedObjectContext) {
        let update: LabelUpdate = self.lastUpdateDefault(for: labelId, userId: userId, context: context)
        
        update.unread = Int32(unread)
        update.total = Int32(total)
        
        if shouldSave {
            let error = context.saveUpstreamIfNeeded()
            if error == nil {
                // Set app badge
                if labelId == MailboxSidebar.Item.allMail.id {
                    self.setAppBadge(unread)
                }
            }
        }
    }
    
    //
    // MARK: - Private
    //
    
    private func lastUpdate(for labelId : String, userId: String, context: NSManagedObjectContext) -> LabelUpdate? {
        return LabelUpdate.lastUpdate(by: labelId, userID: userId, inManagedObjectContext: context)
    }
    
}
