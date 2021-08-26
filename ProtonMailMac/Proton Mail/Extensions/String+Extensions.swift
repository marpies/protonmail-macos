//
//  String+Extensions.swift
//  ProtonMailMac
//
//  Created by Marcel Piešťanský on 22.08.2021.
//

import Foundation
import Crypto

extension String {
    
    //TODO:: add test
    var publicKey : String  {
        var error: NSError?
        let key = CryptoNewKeyFromArmored(self, &error)
        if error != nil {
            return ""
        }
        
        return key?.getArmoredPublicKey(nil) ?? ""
    }
    
    var fingerprint : String {
        var error: NSError?
        let key = CryptoNewKeyFromArmored(self, &error)
        if error != nil {
            return ""
        }
        
        return key?.getFingerprint() ?? ""
    }
    
}

extension String {
    
    var armored : Bool {
        get {
            return self.hasPrefix("-----BEGIN PGP MESSAGE-----")
        }
    }
    
}


extension String {
    
    func decodeBase64() -> Data {
        let decodedData = Data(base64Encoded: self, options: NSData.Base64DecodingOptions(rawValue: 0))
        return decodedData!
    }
    
    func preg_replace_none_regex (_ partten: String, replaceto:String) -> String {
        return self.replacingOccurrences(of: partten, with: replaceto, options: NSString.CompareOptions.caseInsensitive, range: nil)
    }
    
    func preg_replace (_ partten: String, replaceto:String) -> String {
        let options : NSRegularExpression.Options = [.caseInsensitive, .dotMatchesLineSeparators]
        do {
            let regex = try NSRegularExpression(pattern: partten, options:options)
            let replacedString = regex.stringByReplacingMatches(in: self,
                                                                options: NSRegularExpression.MatchingOptions(rawValue: 0),
                                                                range: NSRange(location: 0, length: self.count),
                                                                withTemplate: replaceto)
            if !replacedString.isEmpty && replacedString.count > 0 {
                return replacedString
            }
        } catch let ex as NSError {
            //            PMLog.D("\(ex)")
        }
        return self
    }
    
    func preg_match (_ partten: String) -> Bool {
        let options : NSRegularExpression.Options = [.caseInsensitive, .dotMatchesLineSeparators]
        do {
            let regex = try NSRegularExpression(pattern: partten, options:options)
            return regex.firstMatch(in: self,
                                    options: NSRegularExpression.MatchingOptions(rawValue: 0),
                                    range: NSRange(location: 0, length: self.count)) != nil
        } catch let ex as NSError {
            //            PMLog.D("\(ex)")
        }
        
        return false
    }
    
    subscript (i: Int) -> Character {
        return self[self.index(self.startIndex, offsetBy: i)]
    }
    
    subscript (i: Int) -> String {
        return String(self[i] as Character)
    }
    
}

// MARK: - OpenPGP String extension

extension String {
    
    func decryptMessage(binKeys: [Data], passphrase: String) throws -> String? {
        return try Crypto().decrypt(encrytped: self, privateKey: binKeys, passphrase: passphrase)
    }
    
    func verifyMessage(verifier: [Data], binKeys: [Data], passphrase: String, time : Int64) throws -> ExplicitVerifyMessage? {
        return try Crypto().decryptVerify(encrytped: self, publicKey: verifier, privateKey: binKeys, passphrase: passphrase, verifyTime: time)
    }
    
    func verifyMessage(verifier: [Data], userKeys: [Data], keys: [Key], passphrase: String, time : Int64) throws -> ExplicitVerifyMessage? {
        var firstError : Error?
        for key in keys {
            do {
                if let token = key.token, let signature = key.signature { //have both means new schema. key is
                    if let plaitToken = try token.decryptMessage(binKeys: userKeys, passphrase: passphrase) {
                        //PMLog.D(signature)
                        return try Crypto().decryptVerify(encrytped: self,
                                                          publicKey: verifier,
                                                          privateKey: key.private_key,
                                                          passphrase: plaitToken, verifyTime: time)
                    }
                } else if let token = key.token { //old schema with token - subuser. key is embed singed
                    if let plaitToken = try token.decryptMessage(binKeys: userKeys, passphrase: passphrase) {
                        //TODO:: try to verify signature here embeded signature
                        return try Crypto().decryptVerify(encrytped: self,
                                                          publicKey: verifier,
                                                          privateKey: key.private_key,
                                                          passphrase: plaitToken, verifyTime: time)
                    }
                } else {//normal key old schema
                    return try Crypto().decryptVerify(encrytped: self,
                                                      publicKey: verifier,
                                                      privateKey: userKeys,
                                                      passphrase: passphrase, verifyTime: time)
                }
            } catch let error {
                if firstError == nil {
                    firstError = error
                }
                //PMLog.D(error.localizedDescription)
            }
        }
        if let error = firstError {
            throw error
        }
        return nil
    }
    
    func decryptMessageWithSinglKey(_ privateKey: String, passphrase: String) throws -> String? {
        return try Crypto().decrypt(encrytped: self, privateKey: privateKey, passphrase: passphrase)
    }
    
    func encrypt(withPrivKey key: String, mailbox_pwd: String) throws -> String? {
        return try Crypto().encrypt(plainText: self, privateKey: key, passphrase: mailbox_pwd)
    }
    
    func encrypt(withKey key: Key, userKeys: [Data], mailbox_pwd: String) throws -> String? {
        if let token = key.token, let _ = key.signature { //have both means new schema. key is
            if let plaitToken = try token.decryptMessage(binKeys: userKeys, passphrase: mailbox_pwd) {
                //PMLog.D(signature)
                return try Crypto().encrypt(plainText: self,
                                            publicKey: key.publicKey,
                                            privateKey: key.private_key,
                                            passphrase: plaitToken)
            }
        } else if let token = key.token { //old schema with token - subuser. key is embed singed
            if let plaitToken = try token.decryptMessage(binKeys: userKeys, passphrase: mailbox_pwd) {
                //TODO:: try to verify signature here embeded signature
                return try Crypto().encrypt(plainText: self,
                                            publicKey: key.publicKey,
                                            privateKey: key.private_key,
                                            passphrase: plaitToken)
            }
        }
        return try Crypto().encrypt(plainText: self,
                                    publicKey:  key.publicKey,
                                    privateKey: key.private_key,
                                    passphrase: mailbox_pwd)
    }
    
    func encrypt(withPubKey publicKey: String, privateKey: String, passphrase: String) throws -> String? {
        return try Crypto().encrypt(plainText: self, publicKey: publicKey, privateKey: privateKey, passphrase: passphrase)
    }
    
    func encrypt(withPwd passphrase: String) throws -> String? {
        return try Crypto().encrypt(plainText: self, token: passphrase)
    }
    
    func decrypt(withPwd passphrase: String) throws -> String? {
        return try Crypto().decrypt(encrypted: self, token: passphrase)
    }
}
