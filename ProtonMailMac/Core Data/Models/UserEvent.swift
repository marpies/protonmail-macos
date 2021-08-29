//
//  Contact.swift
//  ProtonMail
//
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

public class UserEvent: NSManagedObject {
    
    @NSManaged public var userID: String
    @NSManaged public var eventID: String
    
}

extension UserEvent {
    
    struct Attributes {
        static let entityName = "UserEvent"
        static let userID = "userID"
        static let eventID = "eventID"
    }
    
    class func userEvent(by userID: String,  inManagedObjectContext context: NSManagedObjectContext) -> UserEvent? {
        return context.managedObjectWithEntityName(Attributes.entityName, matching: [Attributes.userID : userID]) as? UserEvent
    }
        
    class func newUserEvent(userID: String, inManagedObjectContext context: NSManagedObjectContext) -> UserEvent {
        let event = UserEvent(context: context)
        event.userID = userID
        event.eventID = ""
        if let error = event.managedObjectContext?.saveUpstreamIfNeeded() {
            PMLog.D("error: \(error)")
        }
        return event
    }
    
    class func deleteAll(inContext context: NSManagedObjectContext) {
        context.deleteAll(Attributes.entityName)
    }
    
    class func remove(by userID: String, inManagedObjectContext context: NSManagedObjectContext) -> Bool {
        if let toDeletes = context.managedObjectsWithEntityName(Attributes.entityName,
                                                                matching: [Attributes.userID : userID]) as? [UserEvent] {
            for update in toDeletes {
                context.delete(update)
            }
            if let error = context.saveUpstreamIfNeeded() {
                PMLog.D(" error: \(error)")
            } else {
                return true
            }
        }
        return false
    }
}
