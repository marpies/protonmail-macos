//
//  MessageTimePresenting.swift
//  ProtonMailMac
//
//  Created by Marcel Piešťanský on 17.09.2021.
//  Copyright © 2021 marpies. All rights reserved.
//

import Foundation

protocol MessageTimePresenting {
    var dateFormatter: DateFormatter { get }
    
    func getMessageTime(response: Messages.MessageTime) -> String
}

extension MessageTimePresenting {
    
    func getMessageTime(response: Messages.MessageTime) -> String {
        let date: Date
        
        switch response {
        case .today(let messageDate):
            // Show time only
            date = messageDate
            self.dateFormatter.dateStyle = .none
            self.dateFormatter.timeStyle = .short
            
        case .yesterday(_):
            // Show "Yesterday"
            return NSLocalizedString("messageDateYesterdayText", comment: "")
            
        case .other(let messageDate):
            // Show date without time
            date = messageDate
            self.dateFormatter.dateStyle = .long
            self.dateFormatter.timeStyle = .none
        }
        
        return self.dateFormatter.string(from: date)
    }
    
}
