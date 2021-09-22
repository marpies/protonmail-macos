//
//  MessageOpsService.swift
//  ProtonMailMac
//
//  Created by Marcel Piešťanský on 13.09.2021.
//  Copyright © 2021 marpies. All rights reserved.
//

import Foundation
import Swinject
import CoreData

fileprivate typealias CompletionBlock = (_ task: URLSessionDataTask?, _ response: [String: Any]?, _ error: NSError?) -> Void

protocol MessageOpsProcessingDelegate: AnyObject {
    func labelsDidUpdateForMessages(ids: [String], labelId: String)
}

protocol MessageOpsProcessing {
    var delegate: MessageOpsProcessingDelegate? { get set }
    
    @discardableResult
    func label(messageIds: [String], label: String, apply: Bool) -> Bool
    
    @discardableResult
    func mark(messageIds: [String], unread: Bool) -> Bool
}

class MessageOpsService: MessageOpsProcessing, AuthCredentialRefreshing {
    
    private let resolver: Resolver
    private let messageQueue: MessageQueue
    private let userId: String
    private let usersManager: UsersManager
    
    private(set) var auth: AuthCredential?
    private(set) var apiService: ApiService?
    
    weak var delegate: MessageOpsProcessingDelegate?

    init(userId: String, resolver: Resolver) {
        self.userId = userId
        self.resolver = resolver
        self.messageQueue = resolver.resolve(MessageQueue.self, argument: "writeQueue")!
        self.usersManager = resolver.resolve(UsersManager.self)!
        self.apiService = self.resolver.resolve(ApiService.self)!
        self.apiService?.authDelegate = self
    }
    
    @discardableResult
    func label(messageIds: [String], label: String, apply: Bool) -> Bool {
        let db: MessagesDatabaseManaging = self.resolver.resolve(MessagesDatabaseManaging.self)!
        
        guard let messages = db.updateLabel(messageIds: messageIds, label: label, apply: apply, userId: self.userId) else { return false }
        
        self.queue(messages, action: apply ? .label : .unlabel, data1: label)
        
        return true
    }
    
    @discardableResult
    func mark(messageIds: [String], unread: Bool) -> Bool {
        let db: MessagesDatabaseManaging = self.resolver.resolve(MessagesDatabaseManaging.self)!
        
        guard let messages = db.updateUnread(messageIds: messageIds, unread: unread, userId: self.userId) else { return false }
        
        self.queue(messages, action: unread ? .unread : .read)
        
        return true
    }
    
    //
    // MARK: - Auth refreshing
    //
    
    func authCredentialDidRefresh() {
        self.usersManager.save()
    }
    
    func onForceUpgrade() {
        //
    }
    
    func sessionDidRevoke() {
        //
    }
    
    //
    // MARK: - Queue
    //
    
    private func queue(_ messages: [Message], action: MessageAction, data1: String = "", data2: String = "") {
        //self.cachePropertiesForBackground(in: message)
        
        if action == .saveDraft || action == .send || action == .read || action == .unread {
            let ids: [String] = messages.map { $0.objectID.uriRepresentation().absoluteString }
            let _ = self.messageQueue.addMessages(ids, action: action.rawValue, data1: data1, data2: data2, userId: self.userId)
        } else {
            let ids: [String] = messages.compactMap { msg in
                if msg.managedObjectContext != nil && !msg.messageID.isEmpty {
                    return msg.messageID
                }
                return nil
            }
            
            if ids.isEmpty { return }
            
            let _ = self.messageQueue.addMessages(ids, action: action.rawValue, data1: data1, data2: data2, userId: self.userId)
        }
        
        dequeueIfNeeded()
    }
    
    private func dequeueIfNeeded() {
        // for label action: data1 is `to`
        // for forder action: data1 is `from`  data2 is `to`
        guard let (uuid, messageIds, actionString, data1, data2, userId) = self.messageQueue.nextMessage() else { return }
        
        PMLog.D("Process message == dequeue --- \(actionString)")
        if let action = MessageAction(rawValue: actionString) {
            self.messageQueue.isInProgress = true
            
            let completeHandler: CompletionBlock = writeQueueCompletionBlockForElementID(uuid, messageIds: messageIds, actionString: actionString)
            
            //Check userId, if it is empty then assign current userId (Object queued in old version)
            let UID: String = userId.isEmpty ? self.userId : userId
            
            switch action {
            case .saveDraft:
                fatalError("Not implemented yet.")
            case .uploadAtt:
                fatalError("Not implemented yet.")
            case .uploadPubkey:
                fatalError("Not implemented yet.")
            case .deleteAtt:
                fatalError("Not implemented yet.")
            case .send:
                fatalError("Not implemented yet.")
            case .empty:
                fatalError("Not implemented yet.")
            case .read, .unread:
                self.messageAction(messageIds, action: actionString, UID: UID, completion: completeHandler)
            case .delete:
                fatalError("Not implemented yet.")
            case .label:
                self.labelMessage(data1, messageIds: messageIds, UID: UID, completion: completeHandler)
            case .unlabel:
                self.unLabelMessage(data1, messageIds: messageIds, UID: UID, completion: completeHandler)
            case .folder:
                //later use data 1 to handle the failure
                self.labelMessage(data2, messageIds: messageIds, UID: UID, completion: completeHandler)
            }
        } else {
            PMLog.D(" Unsupported action \(actionString), removing from queue.")
            let _ = self.messageQueue.remove(uuid)
        }
    }
    
    private func writeQueueCompletionBlockForElementID(_ elementID: UUID, messageIds: [String], actionString: String) -> CompletionBlock {
        return { task, response, error in
            self.messageQueue.isInProgress = false
            if error == nil {
                if let action = MessageAction(rawValue: actionString) {
                    if action == MessageAction.delete {
                        let db: MessagesDatabaseManaging = self.resolver.resolve(MessagesDatabaseManaging.self)!
                        db.deleteMessages(ids: messageIds)
                    }
                    
                    if action == .send {
                        //after sent, clean the other actions with same messageID from write queue (save and send)
                        self.messageQueue.removeDoubleSent(messageIds: messageIds, actions: [MessageAction.saveDraft.rawValue, MessageAction.send.rawValue])
                    }
                }
                let _ = self.messageQueue.remove(elementID)
                self.dequeueIfNeeded()
            } else {
                PMLog.D(" error: \(String(describing: error))")
                
                var statusCode = 200
                let errorCode = error?.code ?? 200
                var isInternetIssue = false
                
                if let err = error {
                    let errorUserInfo = err.userInfo
                    
                    if let detail = errorUserInfo["com.alamofire.serialization.response.error.response"] as? HTTPURLResponse {
                        statusCode = detail.statusCode
                    } else {
                        if err.domain == NSURLErrorDomain {
                            switch err.code {
                            case NSURLErrorTimedOut,
                                 NSURLErrorCannotConnectToHost,
                                 NSURLErrorCannotFindHost,
                                 NSURLErrorDNSLookupFailed,
                                 NSURLErrorNotConnectedToInternet,
                                 NSURLErrorSecureConnectionFailed,
                                 NSURLErrorDataNotAllowed,
                                 NSURLErrorCannotFindHost:
                                isInternetIssue = true
                            default:
                                break
                            }
                        } else if err.domain == NSPOSIXErrorDomain && err.code == 100 {
                            //Network protocol error
                            isInternetIssue = true
                        }
                        
                        // Show timeout error banner or not reachable banner in mailbox
                        if errorCode == NSURLErrorTimedOut {
                            NotificationCenter.default.post(Notification(name: .MessagesLoadDidTimeout, object: 0, userInfo: nil))
                        } else if isInternetIssue {
                            NotificationCenter.default.post(Notification(name: .MessagesServerUnreachable, object: 1, userInfo: nil))
                        }
                    }
                }
                
                if (statusCode == 404)
                {
                    if  let (_, object) = self.messageQueue.next() {
                        if let element = object as? [String : String] {
                            let count = element["count"]
                            PMLog.D("message queue count : \(String(describing: count))")
                            let _ = self.messageQueue.remove(elementID)
                        }
                    }
                }
                
                //need add try times and check internet status
                if statusCode == 500 && !isInternetIssue {
                    if  let (_, object) = self.messageQueue.next() {
                        if let element = object as? [String : String] {
                            let count = element["count"]
                            PMLog.D("message queue count : \(String(describing: count))")
                            let _ = self.messageQueue.remove(elementID)
                        }
                    }
                }
                
                if statusCode == 200 && errorCode == 9001 {
                    
                } else if statusCode == 200 && errorCode > 1000 {
                    let _ = self.messageQueue.remove(elementID)
                } else if statusCode == 200 && errorCode < 200 && !isInternetIssue {
                    let _ = self.messageQueue.remove(elementID)
                }
                
                if statusCode != 200 && statusCode != 404 && statusCode != 500 && !isInternetIssue {
                    //show error
                    let _ = self.messageQueue.remove(elementID)
                }
                
                if !isInternetIssue {
                    self.dequeueIfNeeded()
                }
            }
        }
    }
    
    //
    // MARK: - Label / unlabel
    //
    
    private func labelMessage(_ labelID: String, messageIds: [String], UID: String, completion: CompletionBlock?) {
        guard let user = self.usersManager.getUser(forId: UID) else {
            completion!(nil, nil, NSError.userLoggedOut())
            return
        }
        
        self.auth = user.auth
        
        let request = ApplyLabelToMessagesRequest(labelID: labelID, messages: messageIds)
        self.apiService?.request(request) { (task, _, error) in
            self.delegate?.labelsDidUpdateForMessages(ids: messageIds, labelId: labelID)
            
            completion?(task, nil, error)
        }
    }
    
    private func unLabelMessage(_ labelID: String, messageIds: [String], UID: String, completion: CompletionBlock?) {
        guard let user = self.usersManager.getUser(forId: UID) else {
            completion!(nil, nil, NSError.userLoggedOut())
            return
        }
        
        self.auth = user.auth
        
        let request = RemoveLabelFromMessagesRequest(labelID: labelID, messages: messageIds)
        self.apiService?.request(request) { (task, _, error) in
            self.delegate?.labelsDidUpdateForMessages(ids: messageIds, labelId: labelID)
            
            completion?(task, nil, error)
        }
    }
    
    //
    // MARK: - Message action
    //
    
    private func messageAction(_ managedObjectIds: [String], action: String, UID: String, completion: CompletionBlock?) {
        guard let user = self.usersManager.getUser(forId: UID) else {
            completion!(nil, nil, NSError.userLoggedOut())
            return
        }
        
        let db: MessagesDatabaseManaging = self.resolver.resolve(MessagesDatabaseManaging.self)!
        if let ids = db.getMessageIds(forURIRepresentations: managedObjectIds) {
            self.auth = user.auth
            
            let request = MessageActionRequest(action: action, ids: ids)
            self.apiService?.request(request, completion: { task, _, error in
                completion?(task, nil, error)
            })
        } else {
            completion?(nil, nil, NSError.unknownError())
        }
    }
    
}
