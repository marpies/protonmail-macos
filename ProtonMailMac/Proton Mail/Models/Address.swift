//
//  File.swift
//  
//
//  Created by Marcel Piešťanský on 22.08.2021.
//

import Foundation

@objc(Address)
final public class Address: NSObject {
    public let address_id: String
    public let email: String   // email address name
    public let status: Int    // 0 is disabled, 1 is enabled, can be set by user
    public let type: Int      // 1 is original PM, 2 is PM alias, 3 is custom domain address
    public let receive: Int    // 1 is active address (Status =1 and has key), 0 is inactive (cannot send or receive)
    public var order: Int      // address order
    // 0 means you can’t send with it 1 means you can pm.me addresses have Send 0 for free users, for instance so do addresses without keys
    public var send: Int
    public let keys: [Key]
    public var display_name: String
    public var signature: String
    
    public required init(addressid: String?,
                         email: String?,
                         order: Int?,
                         receive: Int?,
                         display_name: String?,
                         signature: String?,
                         keys: [Key]?,
                         status: Int?,
                         type: Int?,
                         send: Int?) {
        self.address_id = addressid ?? ""
        self.email = email ?? ""
        self.receive = receive ?? 0
        self.display_name = display_name ?? ""
        self.signature = signature ?? ""
        self.keys = keys ?? [Key]()
        
        self.status = status ?? 0
        self.type = type ?? 0
        
        self.send = send ?? 0
        self.order = order ?? 0
    }
    
}

// MARK: - TODO:: we'd better move to Codable or at least NSSecureCoding when will happen to refactor this part of app from Anatoly
extension Address: NSCoding {
    public func archive() -> Data {
        return try! NSKeyedArchiver.archivedData(withRootObject: self, requiringSecureCoding: false)
    }
    
    static public func unarchive(_ data: Data?) -> Address? {
        guard let data = data else { return nil }
        return try? NSKeyedUnarchiver.unarchivedObject(ofClass: Address.self, from: data)
    }
    
    // the keys all messed up but it works ( don't copy paste there looks really bad)
    fileprivate struct CoderKey {
        static let addressID    = "displayName"
        static let email        = "maxSpace"
        static let order        = "notificationEmail"
        static let receive      = "privateKey"
        static let mailbox      = "publicKey"
        static let display_name = "signature"
        static let signature    = "usedSpace"
        static let keys         = "userKeys"
        
        static let addressStatus = "addressStatus"
        static let addressType   = "addressType"
        static let addressSend   = "addressSendStatus"
    }
    
    public convenience init(coder aDecoder: NSCoder) {
        self.init(
            addressid: aDecoder.decodeStringForKey(CoderKey.addressID),
            email: aDecoder.decodeStringForKey(CoderKey.email),
            order: aDecoder.decodeInteger(forKey: CoderKey.order),
            receive: aDecoder.decodeInteger(forKey: CoderKey.receive),
            display_name: aDecoder.decodeStringForKey(CoderKey.display_name),
            signature: aDecoder.decodeStringForKey(CoderKey.signature),
            keys: aDecoder.decodeObject(forKey: CoderKey.keys) as?  [Key],
            
            status: aDecoder.decodeInteger(forKey: CoderKey.addressStatus),
            type: aDecoder.decodeInteger(forKey: CoderKey.addressType),
            send: aDecoder.decodeInteger(forKey: CoderKey.addressSend)
        )
    }
    
    public func encode(with aCoder: NSCoder) {
        aCoder.encode(address_id, forKey: CoderKey.addressID)
        aCoder.encode(email, forKey: CoderKey.email)
        aCoder.encode(order, forKey: CoderKey.order)
        aCoder.encode(receive, forKey: CoderKey.receive)
        aCoder.encode(display_name, forKey: CoderKey.display_name)
        aCoder.encode(signature, forKey: CoderKey.signature)
        aCoder.encode(keys, forKey: CoderKey.keys)
        
        aCoder.encode(status, forKey: CoderKey.addressStatus)
        aCoder.encode(type, forKey: CoderKey.addressType)
        
        aCoder.encode(send, forKey: CoderKey.addressSend)
    }
}
