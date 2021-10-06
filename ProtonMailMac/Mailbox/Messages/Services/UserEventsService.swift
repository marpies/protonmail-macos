//
//  UserEventsService.swift
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

import Foundation
import Swinject
import PromiseKit

enum UserEventsResponse {
    case cleanUp(String), success([String: Any]), error(NSError)
}

protocol UserEventsProcessing {
    func fetchEvents(forLabel labelId: String, userId: String, completion: @escaping (UserEventsResponse) -> Void)
}

class UserEventsService: UserEventsProcessing, AuthCredentialRefreshing {
    
    private let resolver: Swinject.Resolver
    private let userEvents: UserEventsDatabaseManaging
    private let usersManager: UsersManager
    
    private let incrementalUpdateQueue = DispatchQueue(label: "com.marpies.incrementalUpdateQueue", attributes: [])
    
    private(set) var auth: AuthCredential?
    private(set) var apiService: ApiService?
    
    init(resolver: Swinject.Resolver) {
        self.resolver = resolver
        self.userEvents = resolver.resolve(UserEventsDatabaseManaging.self)!
        self.usersManager = resolver.resolve(UsersManager.self)!
        self.apiService = resolver.resolve(ApiService.self)
        self.apiService?.authDelegate = self
    }
    
    func fetchEvents(forLabel labelId: String, userId: String, completion: @escaping (UserEventsResponse) -> Void) {
        guard let user = self.usersManager.getUser(forId: userId) else {
            completion(.error(NSError.unknownError()))
            return
        }
        
        self.auth = user.auth
        
        let request = EventCheckRequest(eventID: self.userEvents.getLastEventId(forUser: userId))
        self.apiService?.request(request) { (response: EventCheckResponse) in
            if let error = response.error {
                self.processEventCheckError(error, completion: completion)
            } else {
                // todo refresh contacts
//                if response.refresh.contains(.contacts) {
//                    _ = self.contactDataService.cleanUp().ensure {
//                        self.contactDataService.fetchContacts(completion: nil)
//                    }
//                }
                
                if response.refresh.contains(.all) || response.refresh.contains(.mail) || (response.code == 18001) {
                    self.fetchLatestEventId { eventResponse in
                        if eventResponse.eventID.isEmpty {
                            completion(.error(eventResponse.error ?? NSError.unknownError()))
                        } else {
                            completion(.cleanUp(eventResponse.eventID))
                        }
                    }
                } else if response.messages != nil || response.conversations != nil {
                    DispatchQueue.global().async {
                        self.processEvents(conversations: response.conversations, messages: response.messages, response: response, userId: userId) { (res, error) in
                            if let res = res {
                                completion(.success(res))
                            }
                            else {
                                completion(.error(error ?? NSError.unknownError()))
                            }
                        }
                    }
                } else if response.code == 1000 {
                    self.processEvents(conversationEvents: nil, messageEvents: nil, response: response, userId: userId) { res in
                        completion(.success(res))
                    }
                } else {
                    let res: [String: Any] = ["Notices": response.notices ?? [String](), "More" : response.more]
                    completion(.success(res))
                }
            }
        }
    }
    
    //
    // MARK: - Event processing
    //
    
    private func processEvents(conversations: [[String : Any]]?, messages: [[String : Any]]?, response: EventCheckResponse, userId: String, completion: @escaping ([String: Any]?, NSError?) -> Void) {
        // this serial dispatch queue prevents multiple messages from appearing when an incremental update is triggered while another is in progress
        self.incrementalUpdateQueue.sync {
            let db: UserEventsDatabaseProcessing = resolver.resolve(UserEventsDatabaseProcessing.self)!
            db.process(conversations: conversations, messages: messages, userId: userId) { missingMessageIds, error in
                if !missingMessageIds.isEmpty {
                    self.fetchMessageInBatches(messageIDs: missingMessageIds, userId: userId)
                }
                
                if error == nil {
                    self.processEvents(conversationEvents: conversations, messageEvents: messages, response: response, userId: userId) { res in
                        completion(res, nil)
                    }
                } else {
                    completion(nil, error)
                }
            }
        }
    }
    
    private func processEvents(conversationEvents: [[String: Any]]?, messageEvents: [[String: Any]]?, response: EventCheckResponse, userId: String, completion: @escaping ([String: Any]) -> Void) {
        let userEventsDb: UserEventsDatabaseManaging = self.resolver.resolve(UserEventsDatabaseManaging.self)!
        let userEventsProcessing: UserEventsDatabaseProcessing = self.resolver.resolve(UserEventsDatabaseProcessing.self)!
        
        firstly {
            Promise<Void>{ seal in
                userEventsDb.updateEventId(forUser: userId, eventId: response.eventID) {
                    seal.fulfill_()
                }
            }
        }.then { () -> Promise<Void> in
            if response.refresh.contains(.contacts) {
                return Promise()
            }
            return userEventsProcessing.processEvents(contactEmails: response.contactEmails, userId: userId).then { () -> Promise<Void> in
                userEventsProcessing.processEvents(contacts: response.contacts, userId: userId)
            }
        }.then { () -> Promise<Void> in
            Promise<Void> { seal in
                self.incrementalUpdateQueue.sync {
                    userEventsProcessing.processEvents(labels: response.labels, userId: userId).ensure {
                        seal.fulfill_()
                    }.cauterize()
                }
            }
        }.then({ () -> Promise<Void> in
            Promise<Void> { seal in
                self.incrementalUpdateQueue.sync {
                    userEventsProcessing.processEvents(addresses: response.addresses, userId: userId).ensure {
                        seal.fulfill_()
                    }.cauterize()
                }
            }
        })
        .ensure {
            // todo process all events
//            self.processEvents(user: response.user)
//            self.processEvents(userSettings: response.userSettings)
//            self.processEvents(mailSettings: response.mailSettings)
            userEventsProcessing.processEvents(counts: response.messageCounts, userId: userId)
//            self.processEvents(space: response.usedSpace)
            
            var result: [String: Any] = [
                "Notices": response.notices ?? [String](),
                "More": response.more
            ]

            if let messageEvents = messageEvents {
                var updatedMessageIds: Set<String> = []
                var outMessages: [MessageEvent] = []
                for message in messageEvents {
                    let msg = MessageEvent(event: message)
                    if msg.Action == 1 {
                        outMessages.append(msg)
                    } else if (msg.Action == 2 || msg.Action == 3), let id = msg.ID {
                        updatedMessageIds.insert(id)
                    }
                }
                
                result["Messages"] = outMessages
                
                if !updatedMessageIds.isEmpty {
                    result["UpdatedMessages"] = updatedMessageIds
                }
            }
            
            if let conversationEvents = conversationEvents {
                var updatedConversationIds: Set<String> = []
                var outConversations: [ConversationEvent] = []
                for event in conversationEvents {
                    let conversation = ConversationEvent(event: event)
                    if conversation.Action == 1 {
                        outConversations.append(conversation)
                    } else if (conversation.Action == 2 || conversation.Action == 3), let id = conversation.ID {
                        updatedConversationIds.insert(id)
                    }
                }
                
                result["Conversations"] = outConversations
                
                if !updatedConversationIds.isEmpty {
                    result["UpdatedConversations"] = updatedConversationIds
                }
            }
            
            completion(result)
        }.cauterize()
    }
    
    private func fetchMessageInBatches(messageIDs: [String], userId: String) {
        //split the api call in case there are too many messages
        var temp: [String] = []
        for i in 0..<messageIDs.count {
            if temp.count > 20 {
                self.fetchMetadata(forMessages: temp, userId: userId)
                temp.removeAll()
            }
            
            temp.append(messageIDs[i])
        }
        if !temp.isEmpty {
            self.fetchMetadata(forMessages: temp, userId: userId)
        }
    }
    
    private func fetchMetadata(forMessages messageIDs : [String], userId: String) {
        guard !messageIDs.isEmpty else { return }
        
        let request = MessagesByIDRequest(msgIDs: messageIDs)
        self.apiService?.request(request, completion: { _, responseDict, error in
            if var messagesArray = responseDict?["Messages"] as? [[String : Any]] {
                for (index, _) in messagesArray.enumerated() {
                    messagesArray[index]["UserID"] = userId
                }
                
                let db: MessagesDatabaseManaging = self.resolver.resolve(MessagesDatabaseManaging.self)!
                db.saveMessages(messagesArray, forUser: userId) {
                    
                }
            } else {
                let details: String = error?.description ?? "-"
                PMLog.D("MessagesByIDRequest can't get the response Messages: \(details)")
            }
        })
    }
    
    //
    // MARK: - Auth delegate
    //
    
    func sessionDidRevoke() {
        //
    }
    
    func onForceUpgrade() {
        //
    }
    
    func authCredentialDidRefresh() {
        self.usersManager.save()
    }
    
    //
    // MARK: - Private
    //
    
    private func processEventCheckError(_ error: NSError, completion: @escaping (UserEventsResponse) -> Void) {
        if error.code == 18001 {
            self.fetchLatestEventId { response in
                if !response.eventID.isEmpty {
                    print(" event id \(response.eventID)")
                    
                    completion(.cleanUp(response.eventID))
//                    let completionWrapper: CompletionBlock = { task, responseDict, error in
//                        if error == nil {
//                            lastUpdatedStore.clear()
//                            _ = lastUpdatedStore.updateEventID(by: self.userID, eventID: IDRes.eventID, context: context).ensure {
//                                completion?(task, responseDict, error)
//                            }
//                            return
//                        }
//                        completion?(task, responseDict, error)
//                    }
                    
                    // todo remove messages from CoreData
                    // fetch messages for label
                    // todo this func is same for when
                    // response.refresh.contains(.all) || response.refresh.contains(.mail) || (response.code == 18001)
                    
//                    self.cleanMessage().then {
//                        return self.contactDataService.cleanUp()
//                    }.ensure {
//                        self.fetchMessages(byLabel: labelID, time: 0, forceClean: false, completion: completionWrapper)
//                        self.contactDataService.fetchContacts(completion: nil)
//                        self.labelDataService.fetchLabels()
//                    }.cauterize()
                } else {
                    PMLog.D(response.error?.localizedDescription ?? "-")
                    completion(.error(response.error ?? error))
                }
            }
        } else {
            completion(.error(error))
        }
    }
    
    private func fetchLatestEventId(completion: @escaping (EventLatestIDResponse) -> Void) {
        let request = EventLatestIDRequest()
        self.apiService?.request(request) { (response: EventLatestIDResponse) in
            completion(response)
        }
    }
    
}
