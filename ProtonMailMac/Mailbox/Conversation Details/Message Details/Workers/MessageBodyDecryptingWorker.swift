//
//  MessageBodyDecryptingWorker.swift
//  ProtonMailMac
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
//

import Foundation

protocol MessageBodyDecrypting {
    func decrypt(body: String, user: AuthUser) -> String?
}

struct MessageBodyDecryptingWorker: MessageBodyDecrypting {
    
    func decrypt(body: String, user: AuthUser) -> String? {
        let userInfo: UserInfo = user.userInfo
        let mpwd: String = user.auth.mailboxpassword
        let keys: [Key] = userInfo.addressKeys
        
        do {
            let decrypted: String?
            
            if userInfo.newSchema {
                decrypted = try self.decrypt(body: body, keys: keys, userKeys: userInfo.userPrivateKeysArray, passphrase: mpwd)
            } else {
                decrypted = try self.decrypt(body: body, keys: keys, passphrase: mpwd)
            }
            
            return decrypted
        } catch {
            PMLog.D("Error decrypting body: \(error)")
        }
        
        return nil
    }
    
    //
    // MARK: - Private
    //
    
    func decrypt(body: String, keys: [Key], userKeys: [Data], passphrase: String) throws -> String? {
        var firstError : Error?
        var errorMessages: [String] = []
        var newScheme: Int = 0
        var oldSchemaWithToken: Int = 0
        var oldSchema: Int = 0
        for key in keys {
            do {
                if let token = key.token, let _ = key.signature { //have both means new schema. key is
                    newScheme += 1
                    if let plaitToken = try token.decryptMessage(binKeys: userKeys, passphrase: passphrase) {
                        return try body.decryptMessageWithSinglKey(key.private_key, passphrase: plaitToken)
                    }
                } else if let token = key.token { //old schema with token - subuser. key is embed singed
                    oldSchemaWithToken += 1
                    if let plaitToken = try token.decryptMessage(binKeys: userKeys, passphrase: passphrase) {
                        //TODO:: try to verify signature here embeded signature
                        return try body.decryptMessageWithSinglKey(key.private_key, passphrase: plaitToken)
                    }
                } else {//normal key old schema
                    oldSchema += 1
                    return try body.decryptMessage(binKeys: keys.binPrivKeysArray, passphrase: passphrase)
                }
            } catch let error {
                if firstError == nil {
                    firstError = error
                    errorMessages.append(error.localizedDescription)
                }
                
                PMLog.D(error.localizedDescription)
            }
        }
        return nil
    }
    
    func decrypt(body: String, keys: [Key], passphrase: String) throws -> String? {
        var firstError : Error?
        var errorMessages: [String] = []
        for key in keys {
            do {
                return try body.decryptMessageWithSinglKey(key.private_key, passphrase: passphrase)
            } catch let error {
                if firstError == nil {
                    firstError = error
                    errorMessages.append(error.localizedDescription)
                }
                
                PMLog.D(error.localizedDescription)
            }
        }
        return nil
    }
    
}
