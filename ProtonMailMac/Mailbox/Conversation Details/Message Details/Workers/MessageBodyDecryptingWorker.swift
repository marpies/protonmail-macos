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
    func decrypt(message: Messages.Message.Response, user: AuthUser) -> String?
}

struct MessageBodyDecryptingWorker: MessageBodyDecrypting {
    
    func decrypt(message: Messages.Message.Response, user: AuthUser) -> String? {
        guard let body = message.body else { return nil }
        
        let userInfo: UserInfo = user.userInfo
        let mpwd: String = user.auth.mailboxpassword
        let keys: [Key] = userInfo.addressKeys
        let metadata: Messages.Message.Metadata.Response = message.metadata
        
        do {
            let decrypted: String?
            
            if userInfo.newSchema {
                decrypted = try self.decrypt(body: body, keys: keys, userKeys: userInfo.userPrivateKeysArray, passphrase: mpwd)
            } else {
                decrypted = try self.decrypt(body: body, keys: keys, passphrase: mpwd)
            }
            
            return self.parseBody(decrypted, metadata: metadata, isDraft: message.isDraft)
        } catch {
            PMLog.D("Error decrypting body: \(error)")
        }
        
        return nil
    }
    
    //
    // MARK: - Private
    //
    
    private func parseBody(_ decryptedBody: String?, metadata: Messages.Message.Metadata.Response, isDraft: Bool) -> String? {
        guard var body = decryptedBody else { return nil }
        
        if metadata.isPgpMime || metadata.isSignedMime {
            if let mimeMsg = MIMEMessage(string: body) {
                if let html = mimeMsg.mainPart.part(ofType: Message.MimeType.html)?.bodyString {
                    body = html
                } else if let text = mimeMsg.mainPart.part(ofType: Message.MimeType.plainText)?.bodyString {
                    body = text.encodeHtml()
                    body = "<html><body>\(body.ln2br())</body></html>"
                }
                
                let cidParts = mimeMsg.mainPart.partCIDs()
                
                for cidPart in cidParts {
                    if var cid = cidPart.cid,
                       let rawBody = cidPart.rawBodyString {
                        cid = cid.preg_replace("<", replaceto: "")
                        cid = cid.preg_replace(">", replaceto: "")
                        let attType = "image/jpg" //cidPart.headers[.contentType]?.body ?? "image/jpg;name=\"unknow.jpg\""
                        let encode = cidPart.headers[.contentTransferEncoding]?.body ?? "base64"
                        body = body.stringBySetupInlineImage("src=\"cid:\(cid)\"", to: "src=\"data:\(attType);\(encode),\(rawBody)\"")
                    }
                }
                
                /// Cache the decrypted inline attachments
                self.cacheInlineAttachments(for: mimeMsg)
            } else { //backup plan
                body = body.multipartGetHtmlContent()
            }
        } else if metadata.isPgpInline {
            if metadata.isPlainText {
                let head = "<html><head></head><body>"
                // The plain text draft from android and web doesn't have
                // the head, so if the draft contains head
                // It means the draft already encoded
                if !body.hasPrefix(head) {
                    body = body.encodeHtml()
                    body = body.ln2br()
                }
                return body
            } else if metadata.isMultipartMixed {
                ///TODO:: clean up later
                if let mimeMsg = MIMEMessage(string: body) {
                    if let html = mimeMsg.mainPart.part(ofType: Message.MimeType.html)?.bodyString {
                        body = html
                    } else if let text = mimeMsg.mainPart.part(ofType: Message.MimeType.plainText)?.bodyString {
                        body = text.encodeHtml()
                        body = "<html><body>\(body.ln2br())</body></html>"
                    }
                    
                    if let cidPart = mimeMsg.mainPart.partCID(),
                       var cid = cidPart.cid,
                       let rawBody = cidPart.rawBodyString {
                        cid = cid.preg_replace("<", replaceto: "")
                        cid = cid.preg_replace(">", replaceto: "")
                        let attType = "image/jpg" //cidPart.headers[.contentType]?.body ?? "image/jpg;name=\"unknow.jpg\""
                        let encode = cidPart.headers[.contentTransferEncoding]?.body ?? "base64"
                        body = body.stringBySetupInlineImage("src=\"cid:\(cid)\"", to: "src=\"data:\(attType);\(encode),\(rawBody)\"")
                    }
                    
                    /// Cache the decrypted inline attachments
                    self.cacheInlineAttachments(for: mimeMsg)
                } else { //backup plan
                    body = body.multipartGetHtmlContent()
                }
            } else {
                return body
            }
        }
        if metadata.isPlainText {
            if isDraft {
                return body
            } else {
                body = body.encodeHtml()
                return body.ln2br()
            }
        }
        return body
    }
    
    private func decrypt(body: String, keys: [Key], userKeys: [Data], passphrase: String) throws -> String? {
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
    
    private func decrypt(body: String, keys: [Key], passphrase: String) throws -> String? {
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
    
    private func cacheInlineAttachments(for message: MIMEMessage) {
        let atts: [Part] = message.mainPart.findAtts()
        var inlineAtts: [AttachmentInline] = []
        for att in atts {
            if let filename = att.getFilename()?.clear {
                let data = att.data
                let path = FileManager.default.attachmentsDirectory.appendingPathComponent(filename)
                do {
                    try data.write(to: path, options: [.atomic])
                } catch {
                    continue
                }
                inlineAtts.append(AttachmentInline(fnam: filename, size: data.count, mime: filename.mimeType(), path: path))
            }
        }
        
        // todo assign tempAtts on Message object
//        message.tempAtts = inlineAtts
    }
    
}
