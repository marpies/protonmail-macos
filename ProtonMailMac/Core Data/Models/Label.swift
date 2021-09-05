//
//  Label.swift
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


public class Label: NSManagedObject {
    @NSManaged public var userID: String
    
    @NSManaged public var parentID: String
    
    @NSManaged public var labelID: String
    @NSManaged public var name: String
    
    /// label color
    @NSManaged public var color: String
    
    /// 0 = show the label in the sidebar, 1 = hide label from sidebar.
    @NSManaged public var isDisplay: Bool
    
    /// 1 => Message Labels (default), 2 => Contact Groups
    @NSManaged public var type: NSNumber
    
    /// 0 => inclusive (label), 1 => exclusive (folder), message type only
    @NSManaged public var exclusive: Bool
    
    /// start at 1 , lower number on the top
    @NSManaged public var order: NSNumber
    
    @NSManaged public var messages: NSSet
    @NSManaged public var emails: NSSet
}


// lableID 
//    case draft = 1
//    case inbox = 0
//    case outbox = 2
//    case spam = 4
//    case archive = 6
//    case trash = 3
//    case allmail = 5
//    case starred = 10


extension Label {
    
    var spam : Bool {
        get {
            return self.labelID == "4"
        }
    }
    
    var trash : Bool {
        get {
            return self.labelID == "3"
        }
    }
    
    var draft : Bool {
        get {
            return self.labelID == "1"
        }
    }
    
    var defaultOrder: Int {
        switch self.labelID {
        case "0":
            return 1
        case "1", "8":
            return 2
        case "2", "7":
            return 3
        case "3":
            return 7
        case "4":
            return 6
        case "5":
            return 8
        case "6":
            return 5
        case "10":
            return 4
        default:
            fatalError("Unexpected application state.")
        }
    }
    
}
