//
//  Conversation.swift
//  ProtonMailMac
//
//  Created by Marcel Piešťanský on 16.09.2021.
//  Copyright © 2021 marpies. All rights reserved.
//

import Foundation
import CoreData

public class Conversation: NSManagedObject {
    
    @NSManaged public var conversationID: String
    @NSManaged public var numAttachments: NSNumber
    @NSManaged public var numMessages: NSNumber
    @NSManaged public var numUnread: NSNumber
    @NSManaged public var order: NSNumber
    
    /// [ { "Address":"", "Name":"" } ]
    @NSManaged public var senders: String?
    
    /// [ { "Address":"", "Name":"" } ]
    @NSManaged public var recipients: String
    
    @NSManaged public var subject: String
    
    @NSManaged public var time: Date?
    
    @NSManaged public var userID: String
    
    @NSManaged public var labels: NSSet
    @NSManaged public var messages: NSSet
    
}
