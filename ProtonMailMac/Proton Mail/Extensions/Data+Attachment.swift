//
//  Data+Attachment.swift
//  ProtonMailMac
//
//  Created by Marcel Piešťanský on 24.09.2021.
//  Copyright © 2021 marpies. All rights reserved.
//

import Foundation
import Crypto

extension Data {
    func decryptAttachment(keyPackage: Data, userKeys: [Data], passphrase: String, keys: [Key]) throws -> Data? {
        var firstError : Error?
        for key in keys {
            do {
                if let token = key.token, let signature = key.signature { //have both means new schema. key is
                    if let plaitToken = try token.decryptMessage(binKeys: userKeys, passphrase: passphrase) {
                        PMLog.D(signature)
                        return try Crypto().decryptAttachment(keyPacket: keyPackage,
                                                              dataPacket: self,
                                                              privateKey: key.private_key,
                                                              passphrase: plaitToken)
                    }
                } else if let token = key.token { //old schema with token - subuser. key is embed singed
                    if let plaitToken = try token.decryptMessage(binKeys: userKeys, passphrase: passphrase) {
                        //TODO:: try to verify signature here embeded signature
                        return try Crypto().decryptAttachment(keyPacket: keyPackage,
                                                              dataPacket: self,
                                                              privateKey: key.private_key,
                                                              passphrase: plaitToken)
                    }
                } else {//normal key old schema
                    return try Crypto().decryptAttachment(keyPacket: keyPackage,
                                                          dataPacket: self,
                                                          privateKey: userKeys,
                                                          passphrase: passphrase)
                }
            } catch let error {
                if firstError == nil {
                    firstError = error
                }
                PMLog.D(error.localizedDescription)
            }
        }
        if let error = firstError {
            throw error
        }
        return nil
    }
    
    
    func decryptAttachment(_ keyPackage: Data, passphrase: String, privKeys: [Data]) throws -> Data? {
        return try Crypto().decryptAttachment(keyPacket: keyPackage, dataPacket: self, privateKey: privKeys, passphrase: passphrase)
    }
    
    func decryptAttachmentWithSingleKey(_ keyPackage: Data, passphrase: String, privateKey: String) throws -> Data? {
        return try Crypto().decryptAttachment(keyPacket: keyPackage, dataPacket: self, privateKey: privateKey, passphrase: passphrase)
    }
    
    
    func signAttachment(byPrivKey: String, passphrase: String) throws -> String? {
        return try Crypto().signDetached(plainData: self, privateKey: byPrivKey, passphrase: passphrase)
    }
    
    func encryptAttachment(fileName:String, pubKey: String) throws -> SplitMessage? {
        return try Crypto().encryptAttachment(plainData: self, fileName: fileName, publicKey: pubKey)
    }
    
    // could remove and dirrectly use Crypto()
    static func makeEncryptAttachmentProcessor(fileName:String, totalSize: Int, pubKey: String) throws -> AttachmentProcessor {
        return try Crypto().encryptAttachmentLowMemory(fileName: fileName, totalSize: totalSize, publicKey: pubKey)
    }
    
    //key packet part
    func getSessionFromPubKeyPackage(_ passphrase: String, privKeys: [Data]) throws -> SymmetricKey? {
        return try Crypto().getSession(keyPacket: self, privateKeys: privKeys, passphrase: passphrase)
    }
    
    //key packet part
    func getSessionFromPubKeyPackage(addrPrivKey: String, passphrase: String) throws -> SymmetricKey? {
        return try Crypto().getSession(keyPacket: self, privateKey: addrPrivKey, passphrase: passphrase)
    }
    
    //key packet part
    func getSessionFromPubKeyPackage(userKeys: [Data], passphrase: String, keys: [Key]) throws -> SymmetricKey? {
        var firstError : Error?
        for key in keys {
            do {
                if let token = key.token, let signature = key.signature { //have both means new schema. key is
                    if let plainToken = try token.decryptMessage(binKeys: userKeys, passphrase: passphrase) {
                        PMLog.D(signature)
                        return try Crypto().getSession(keyPacket: self, privateKey: key.private_key, passphrase: plainToken)
                    }
                } else if let token = key.token { //old schema with token - subuser. key is embed singed
                    if let plainToken = try token.decryptMessage(binKeys: userKeys, passphrase: passphrase) {
                        //TODO:: try to verify signature here embeded signature
                        return try Crypto().getSession(keyPacket: self, privateKey: key.private_key, passphrase: plainToken)
                    }
                } else {//normal key old schema
                    return try Crypto().getSession(keyPacket: self, privateKeys: userKeys, passphrase: passphrase)
                }
            } catch let error {
                if firstError == nil {
                    firstError = error
                }
                PMLog.D(error.localizedDescription)
            }
        }
        if let error = firstError {
            throw error
        }
        return nil
    }
}
