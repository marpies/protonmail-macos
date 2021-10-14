//
//  ConversationOpsService.swift
//  ProtonMailMac
//
//  Created by Marcel Piešťanský on 20.09.2021.
//  Copyright © 2021 marpies. All rights reserved.
//

import Foundation
import Swinject

fileprivate typealias CompletionBlock = (_ task: URLSessionDataTask?, _ response: [String: Any]?, _ error: NSError?) -> Void

protocol ConversationOpsProcessingDelegate: AnyObject {
    func labelsDidUpdateForConversations(ids: [String], labelId: String)
}

protocol ConversationOpsProcessing {
    var delegate: ConversationOpsProcessingDelegate? { get set }
    
    @discardableResult
    func label(conversationIds: [String], label: String, apply: Bool, includingMessages: Bool) -> Bool
    
    @discardableResult
    func mark(conversationIds: [String], unread: Bool) -> Bool
}

class ConversationOpsService: ConversationOpsProcessing {
    
    private let resolver: Resolver
    private let messageQueue: MessageQueue
    private let userId: String
    private let usersManager: UsersManager
    private let apiService: ApiService
    
    weak var delegate: ConversationOpsProcessingDelegate?
    
    init(userId: String, apiService: ApiService, resolver: Resolver) {
        self.userId = userId
        self.apiService = apiService
        self.resolver = resolver
        self.messageQueue = resolver.resolve(MessageQueue.self, argument: "writeQueue")!
        self.usersManager = resolver.resolve(UsersManager.self)!
    }
    
    //
    // MARK: - Public
    //
    
    @discardableResult
    func label(conversationIds: [String], label: String, apply: Bool, includingMessages: Bool) -> Bool {
        let db: ConversationsDatabaseManaging = self.resolver.resolve(ConversationsDatabaseManaging.self)!
        
        guard let conversations = db.updateLabel(conversationIds: conversationIds, label: label, apply: apply, includingMessages: includingMessages, userId: self.userId) else { return false }
        
        self.queue(conversations, action: apply ? .label : .unlabel, data1: label)
        
        return true
    }
    
    @discardableResult
    func mark(conversationIds: [String], unread: Bool) -> Bool {
        let db: ConversationsDatabaseManaging = self.resolver.resolve(ConversationsDatabaseManaging.self)!
        
        guard let conversations = db.updateUnread(conversationIds: conversationIds, unread: unread, userId: self.userId) else { return false }
        
        self.queue(conversations, action: unread ? .unread : .read)
        
        return true
    }
    
    //
    // MARK: - Queue
    //
    
    private func queue(_ messages: [Conversation], action: ConversationAction, data1: String = "", data2: String = "") {
        //self.cachePropertiesForBackground(in: message)
        
        if action == .read || action == .unread {
            let ids: [String] = messages.map { $0.objectID.uriRepresentation().absoluteString }
            let _ = self.messageQueue.addMessages(ids, action: action.rawValue, data1: data1, data2: data2, userId: self.userId)
        } else {
            let ids: [String] = messages.compactMap { msg in
                if msg.managedObjectContext != nil && !msg.conversationID.isEmpty {
                    return msg.conversationID
                }
                return nil
            }
            
            if ids.isEmpty { return }
            
            let _ = self.messageQueue.addMessages(ids, action: action.rawValue, data1: data1, data2: data2, userId: self.userId)
        }
        
        self.dequeueIfNeeded()
    }
    
    private func dequeueIfNeeded() {
        // for label action: data1 is `to`
        // for forder action: data1 is `from`  data2 is `to`
        guard let (uuid, conversationIds, actionString, data1, data2, userId) = self.messageQueue.nextMessage() else { return }
        
        PMLog.D("Process message == dequeue --- \(actionString)")
        if let action = ConversationAction(rawValue: actionString) {
            self.messageQueue.isInProgress = true
            
            let completeHandler: CompletionBlock = writeQueueCompletionBlockForElementID(uuid, conversationIds: conversationIds, actionString: actionString)
            
            //Check userId, if it is empty then assign current userId (Object queued in old version)
            let UID: String = userId.isEmpty ? self.userId : userId
            
            switch action {
            case .read, .unread:
                self.conversationAction(conversationIds, action: actionString, UID: UID, completion: completeHandler)
            case .delete:
                fatalError("Not implemented yet.")
            case .label:
                self.labelConversation(data1, conversationIds: conversationIds, UID: UID, completion: completeHandler)
            case .unlabel:
                self.unLabelConversation(data1, conversationIds: conversationIds, UID: UID, completion: completeHandler)
            case .folder:
                //later use data 1 to handle the failure
                self.labelConversation(data2, conversationIds: conversationIds, UID: UID, completion: completeHandler)
            }
        } else {
            PMLog.D(" Unsupported action \(actionString), removing from queue.")
            let _ = self.messageQueue.remove(uuid)
        }
    }
    
    private func writeQueueCompletionBlockForElementID(_ elementID: UUID, conversationIds: [String], actionString: String) -> CompletionBlock {
        return { task, response, error in
            self.messageQueue.isInProgress = false
            if error == nil {
                if let action = ConversationAction(rawValue: actionString) {
                    if action == ConversationAction.delete {
                        let db: ConversationsDatabaseManaging = self.resolver.resolve(ConversationsDatabaseManaging.self)!
                        db.deleteConversations(ids: conversationIds)
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
                            NotificationCenter.default.post(Notification(name: .ConversationsLoadDidTimeout, object: 0, userInfo: nil))
                        } else if isInternetIssue {
                            NotificationCenter.default.post(Notification(name: .ConversationsServerUnreachable, object: 1, userInfo: nil))
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
    
    private func labelConversation(_ labelID: String, conversationIds: [String], UID: String, completion: CompletionBlock?) {
        guard let _ = self.usersManager.getUser(forId: UID) else {
            completion!(nil, nil, NSError.userLoggedOut())
            return
        }
        
        let request = ApplyLabelToConversationsRequest(labelID: labelID, conversationIds: conversationIds)
        self.apiService.request(request) { (task, _, error) in
            self.delegate?.labelsDidUpdateForConversations(ids: conversationIds, labelId: labelID)
            
            completion?(task, nil, error)
        }
    }
    
    private func unLabelConversation(_ labelID: String, conversationIds: [String], UID: String, completion: CompletionBlock?) {
        guard let _ = self.usersManager.getUser(forId: UID) else {
            completion!(nil, nil, NSError.userLoggedOut())
            return
        }
        
        let request = RemoveLabelFromConversationsRequest(labelID: labelID, conversationIds: conversationIds)
        self.apiService.request(request) { (task, _, error) in
            self.delegate?.labelsDidUpdateForConversations(ids: conversationIds, labelId: labelID)
            
            completion?(task, nil, error)
        }
    }
    
    //
    // MARK: - Message action
    //
    
    private func conversationAction(_ managedObjectIds: [String], action: String, UID: String, completion: CompletionBlock?) {
        guard let _ = self.usersManager.getUser(forId: UID) else {
            completion!(nil, nil, NSError.userLoggedOut())
            return
        }
        
        let db: ConversationsDatabaseManaging = self.resolver.resolve(ConversationsDatabaseManaging.self)!
        if let ids = db.getConversationIds(forURIRepresentations: managedObjectIds) {
            let request = ConversationActionRequest(action: action, ids: ids)
            self.apiService.request(request, completion: { task, _, error in
                completion?(task, nil, error)
            })
        } else {
            completion?(nil, nil, NSError.unknownError())
        }
    }
    
}
