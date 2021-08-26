//
//  File.swift
//  
//
//  Created by Marcel Piešťanský on 22.08.2021.
//

import Foundation

@objc(Key)
final public class Key: NSObject {
    public let key_id: String
    public var private_key: String
    public var is_updated: Bool = false
    public var keyflags: Int = 0
    
    // key migration step 1 08/01/2019
    public var token: String?
    public var signature: String?
    
    // old activetion flow
    public var activation: String? // armed pgp msg, token encrypted by user's public key and
    
    public required init(key_id: String?, private_key: String?,
                         token: String?, signature: String?, activation: String?,
                         isupdated: Bool) {
        self.key_id = key_id ?? ""
        self.private_key = private_key ?? ""
        self.is_updated = isupdated
        
        self.token = token
        self.signature = signature
        
        self.activation = activation
    }
    
    public var newSchema: Bool {
        return signature != nil
    }
}

extension Key: NSCoding {
    
    private struct CoderKey {
        static let keyID          = "keyID"
        static let privateKey     = "privateKey"
        static let fingerprintKey = "fingerprintKey"
        
        static let Token     = "Key.Token"
        static let Signature = "Key.Signature"
        //
        static let Activation = "Key.Activation"
    }
    
    static func unarchive(_ data: Data?) -> [Key]? {
        guard let data = data else { return nil }
        
        return NSKeyedUnarchiver.unarchiveObject(with: data) as? [Key]
    }
    
    public convenience init(coder aDecoder: NSCoder) {
        self.init(
            key_id: aDecoder.decodeStringForKey(CoderKey.keyID),
            private_key: aDecoder.decodeStringForKey(CoderKey.privateKey),
            token: aDecoder.decodeStringForKey(CoderKey.Token),
            signature: aDecoder.decodeStringForKey(CoderKey.Signature),
            activation: aDecoder.decodeStringForKey(CoderKey.Activation),
            isupdated: false)
    }
    
    public func encode(with aCoder: NSCoder) {
        aCoder.encode(key_id, forKey: CoderKey.keyID)
        aCoder.encode(private_key, forKey: CoderKey.privateKey)
        
        // new added
        aCoder.encode(token, forKey: CoderKey.Token)
        aCoder.encode(signature, forKey: CoderKey.Signature)
        
        //
        aCoder.encode(activation, forKey: CoderKey.Activation)
        
        // TODO:: fingerprintKey is deprecated, need to "remove and clean"
        aCoder.encode("", forKey: CoderKey.fingerprintKey)
    }
}

extension Key {
    
    public var publicKey : String {
        return self.private_key.publicKey
    }
    
    public var fingerprint : String {
        return self.private_key.fingerprint
    }
    
    public var shortFingerpritn: String {
        let fignerprint = self.fingerprint
        if fignerprint.count > 8 {
            return String(fignerprint.prefix(8))
        }
        return fignerprint
    }
}
