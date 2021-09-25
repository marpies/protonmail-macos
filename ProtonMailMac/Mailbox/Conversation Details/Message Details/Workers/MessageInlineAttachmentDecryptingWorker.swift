//
//  MessageInlineAttachmentDecryptingWorker.swift
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
import Swinject

protocol MessageInlineAttachmentDecrypting {
    /// Decrypts the inline attachments contained within the message body.
    /// - Parameters:
    ///   - messageBody: The message body to process.
    ///   - messageId: The message id.
    ///   - user: The user who owns the message.
    ///   - completion: Completion handler, providing the new message body or nil if no changes were made.
    func decryptInlineAttachments(inBody messageBody: String, messageId: String, user: AuthUser, completion: @escaping (String?) -> Void)
}

struct MessageInlineAttachmentDecryptingWorker: MessageInlineAttachmentDecrypting {
    
    private let resolver: Resolver
    private let apiService: ApiService

    init(resolver: Resolver, apiService: ApiService) {
        self.resolver = resolver
        self.apiService = apiService
    }
    
    func decryptInlineAttachments(inBody messageBody: String, messageId: String, user: AuthUser, completion: @escaping (String?) -> Void) {
        let db: MessagesDatabaseManaging = self.resolver.resolve(MessagesDatabaseManaging.self)!
        guard let message = db.loadMessage(id: messageId),
              let attachments = message.attachments as? Set<Attachment> else {
            completion(nil)
            return
        }
        
        let inlineAttachments: [Attachment] = attachments.filter { $0.inline() && $0.contentID()?.isEmpty == false }
        
        guard !inlineAttachments.isEmpty else {
            completion(nil)
            return
        }
        
        let checkCount: Int = inlineAttachments.count
        let group: DispatchGroup = DispatchGroup()
        let queue: DispatchQueue = DispatchQueue(label: "AttachmentQueue", qos: .userInitiated)
        let stringsQueue: DispatchQueue = DispatchQueue(label: "StringsQueue")
        
        var strings: [String:String] = [:]
        for att in inlineAttachments {
            group.enter()
            let item: DispatchWorkItem = DispatchWorkItem {
                self.decrypt(attachment: att, user: user) { base64String in
                    if let base64 = base64String, let contentId = att.contentID() {
                        stringsQueue.sync {
                            strings["src=\"cid:\(contentId)\""] = "src=\"data:\(att.mimeType);base64,\(base64)\""
                        }
                    }
                    group.leave()
                }
            }
            queue.async(group: group, execute: item)
        }
        
        group.notify(queue: .main) {
            if checkCount == strings.count {
                var updatedBody: String = messageBody
                for (cid, base64) in strings {
                    if let token = updatedBody.range(of: cid) {
                        updatedBody.replaceSubrange(token, with: base64)
                    }
                }
                
                completion(updatedBody)
            } else {
                completion(nil)
            }
        }
    }
    
    //
    // MARK: - Private
    //
    
    private func decrypt(attachment: Attachment, user: AuthUser, completion: @escaping (String?) -> Void) {
        if let ctx = attachment.managedObjectContext {
            ctx.perform {
                if let localURL = attachment.localURL, FileManager.default.fileExists(atPath: localURL.path, isDirectory: nil) {
                    completion(attachment.base64DecryptAttachment(userInfo: user.userInfo, passphrase: user.auth.mailboxpassword))
                    return
                }
                
                if let data = attachment.fileData, data.count > 0 {
                    completion(attachment.base64DecryptAttachment(userInfo: user.userInfo, passphrase: user.auth.mailboxpassword))
                    return
                }
                
                // Download attachment
                self.downloadAttachment(attachment) { _, fileUrl, error in
                    if let fileUrl = fileUrl {
                        let db: AttachmentsDatabaseManaging = self.resolver.resolve(AttachmentsDatabaseManaging.self)!
                        db.update(attachment: attachment, fileUrl: fileUrl) { _ in
                            ctx.perform {
                                completion(attachment.base64DecryptAttachment(userInfo: user.userInfo, passphrase: user.auth.mailboxpassword))
                            }
                        }
                    } else {
                        completion(nil)
                    }
                }
            }
        } else {
            completion(nil)
        }
    }
    
    func downloadAttachment(_ attachment: Attachment, completion: @escaping ((URLResponse?, URL?, NSError?) -> Void)) {
        if attachment.downloaded, let localURL = attachment.localURL {
            completion(nil, localURL, nil)
            return
        }
        
        // TODO: check for existing download tasks and return that task rather than start a new download
        if attachment.managedObjectContext != nil {
            let fileUrl: URL = FileManager.default.attachmentsDirectory.appendingPathComponent(attachment.attachmentID)
            let request: DownloadAttachmentRequest = DownloadAttachmentRequest(attachmentId: attachment.attachmentID, destinationURL: fileUrl)
            
            self.apiService.download(request) { response, url, error in
                DispatchQueue.main.async {
                    completion(response, url, error)
                }
            }
        } else {
            PMLog.D("The attachment not exist")
            completion(nil, nil, nil)
        }
    }
    
}
