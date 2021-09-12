//
//  EventAPI.swift
//  ProtonMail - Created on 6/26/15.
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

public enum EventAPI {
    public static let path: String = "events"
    
}

/// TODO:: refactor the events they have same format

enum EventAction : Int {
    case delete = 0
    case insert = 1
    case update1 = 2
    case update2 = 3
    
    case unknown = 255
}

class Event {
    var action : EventAction
    var ID : String?
    
    init(id: String?, action: EventAction) {
        self.ID = id
        self.action = action
    }
    
}

// TODO:: remove the hard convert
final class MessageEvent {
    var Action : Int?
    var ID : String?
    var message : [String : Any]?
    init(event: [String : Any]) {
        self.Action = (event["Action"] as? Int)
        self.message =  event["Message"] as? [String : Any]
        self.ID =  (event["ID"] as? String)
        self.message?["ID"] = self.ID
        self.message?["needsUpdate"] = false
    }
}

final class ContactEvent {
    enum UpdateType : Int {
        case delete = 0
        case insert = 1
        case update = 2
        
        case unknown = 255
    }
    var action : UpdateType
    
    var ID : String?
    var contact : [String : Any]?
    var contacts : [[String : Any]] = []
    init(event: [String : Any]) {
        let actionInt = event["Action"] as? Int ?? 255
        self.action = UpdateType(rawValue: actionInt) ?? .unknown
        self.contact =  event["Contact"] as? [String : Any]
        self.ID =  (event["ID"] as? String)
        
        guard let contact = self.contact else {
            return
        }
        
        self.contacts.append(contact)
    }
}

final class EmailEvent {
    enum UpdateType : Int {
        case delete = 0
        case insert = 1
        case update = 2
        
        case unknown = 255
    }
    
    var action : UpdateType
    var ID : String!  //emailID
    var email : [String : Any]?
    var contacts : [[String : Any]] = []
    init(event: [String : Any]!) {
        let actionInt = event["Action"] as? Int ?? 255
        self.action = UpdateType(rawValue: actionInt) ?? .unknown
        self.email =  event["ContactEmail"] as? [String : Any]
        self.ID =  event["ID"] as? String ?? ""
        
        guard let email = self.email else {
            return
        }
        
        guard let contactID = email["ContactID"],
              let name = email["Name"] else {
            return
        }
        
        let newContact : [String : Any] = [
            "ID" : contactID,
            "Name" : name,
            "ContactEmails" : [email]
        ]
        self.contacts.append(newContact)
    }
    
}

final class LabelEvent {
    var Action : Int?
    var ID : String?
    var label : [String : Any]?
    
    init(event: [String : Any]) {
        self.Action = (event["Action"] as? Int)
        self.label =  event["Label"] as? [String : Any]
        self.ID =  (event["ID"] as? String)
    }
}


final class AddressEvent : Event {
    var address : [String : Any]?
    init(event: [String : Any]) {
        let actionInt = event["Action"] as? Int ?? 255
        super.init(id: event["ID"] as? String,
                   action: EventAction(rawValue: actionInt) ?? .unknown)
        self.address =  event["Address"] as? [String : Any]
    }
}



