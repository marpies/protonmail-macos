//
//  EventCheckResponse.swift
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

struct RefreshStatus : OptionSet {
    let rawValue: Int
    //255 means throw out client cache and reload everything from server, 1 is mail, 2 is contacts
    static let ok       = RefreshStatus([])
    static let mail     = RefreshStatus(rawValue: 1 << 0)
    static let contacts = RefreshStatus(rawValue: 1 << 1)
    static let all      = RefreshStatus(rawValue: 0xFF)
}

final class EventCheckResponse : Response {
    var eventID : String = ""
    var refresh : RefreshStatus = .ok
    var more : Int = 0
    
    var messages : [[String : Any]]?
    var conversations : [[String : Any]]?
    var contacts : [[String : Any]]?
    var contactEmails : [[String : Any]]?
    var labels : [[String : Any]]?
    
    var subscription : [String : Any]? //TODO:: we will use this when we impl in app purchase
    
    var user : [String : Any]?
    var userSettings : [String : Any]?
    var mailSettings : [String : Any]?
    
    var vpnSettings : [String : Any]? //TODO:: vpn settings events, to use this when we add vpn setting in the app
    var invoices : [String : Any]? //TODO:: use when we add invoice setting
    var members : [[String : Any]]? //TODO:: use when we add memebers setting in the app
    var domains : [[String : Any]]? //TODO:: use when we add domain configure in the app
    
    var addresses : [[String : Any]]?
    
    var organization : [String : Any]? //TODO:: use when we add org setting in the app
    
    var conversationCounts: [[String: Any]]?
    
    /// Bytes, divide by (1024*1024) to get MB
    var usedSpace : Int64?
    var notices : [String]?
    
    override func parseResponse(_ response: [String : Any]) -> Bool {
        self.eventID = response["EventID"] as? String ?? ""
        self.refresh = RefreshStatus(rawValue: response["Refresh"] as? Int ?? 0)
        self.more    = response["More"] as? Int ?? 0
        
        self.messages      = response["Messages"] as? [[String : Any]]
        self.conversations = response["Conversations"] as? [[String : Any]]
        self.contacts      = response["Contacts"] as? [[String : Any]]
        self.contactEmails = response["ContactEmails"] as? [[String : Any]]
        self.labels        = response["Labels"] as? [[String : Any]]
        
        //self.subscription = response["Subscription"] as? [String : Any]
        
        self.user         = response["User"] as? [String : Any]
        self.userSettings = response["UserSettings"] as? [String : Any]
        self.mailSettings = response["MailSettings"] as? [String : Any]
        
        //self.vpnSettings = response["VPNSettings"] as? [String : Any]
        //self.invoices = response["Invoices"] as? [String : Any]
        //self.members  = response["Members"] as? [[String : Any]]
        //self.domains  = response["Domains"] as? [[String : Any]]
        
        self.addresses  = response["Addresses"] as? [[String : Any]]
        
        //self.organization = response["Organization"] as? [String : Any]
        
        self.conversationCounts = response["ConversationCounts"] as? [[String : Any]]
        
        self.usedSpace = response["UsedSpace"] as? Int64
        self.notices = response["Notices"] as? [String]
        
        return true
    }
}
