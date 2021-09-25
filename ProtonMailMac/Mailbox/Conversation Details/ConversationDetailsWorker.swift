//
//  ConversationDetailsWorker.swift
//  ProtonMailMac
//
//  Created by Marcel Piešťanský on 17.09.2021.
//  Copyright (c) 2021 marpies. All rights reserved.
//

import Foundation
import Swinject

protocol ConversationDetailsWorkerDelegate: AnyObject {
    func conversationDidLoad(response: ConversationDetails.Load.Response)
    func conversationLoadDidFail(response: ConversationDetails.LoadError.Response)
    func conversationMessageDidUpdate(response: ConversationDetails.UpdateMessage.Response)
    func conversationDidUpdate(response: ConversationDetails.UpdateConversation.Response)
    func conversationMessageBodyLoadDidBegin(response: ConversationDetails.MessageContentLoadDidBegin.Response)
    func conversationMessageBodyDidLoad(response: ConversationDetails.MessageContentLoaded.Response)
    func conversationMessageBodyCollapse(response: ConversationDetails.MessageContentCollapsed.Response)
    func conversationMessageBodyLoadDidFail(response: ConversationDetails.MessageContentError.Response)
}

class ConversationDetailsWorker: AuthCredentialRefreshing, MessageToModelConverting, ConversationToModelConverting, MessageOpsProcessingDelegate, ConversationOpsProcessingDelegate {

	private let resolver: Resolver
    private let usersManager: UsersManager
    
    private(set) var auth: AuthCredential?
    private(set) var apiService: ApiService?
    
    /// Previously loaded converation id.
    private var conversationId: String?
    
    /// Current conversation model.
    private var conversation: ConversationDetails.Conversation.Response?
    
    private var conversationUpdateObserver: NSObjectProtocol?
    
    private var activeUserId: String? {
        return self.usersManager.activeUser?.userId
    }
    
    /// Label id for the model conversion, use "all mail" to have info about folders parsed.
    let labelId: String = MailboxSidebar.Item.allMail.id

	weak var delegate: ConversationDetailsWorkerDelegate?

	init(resolver: Resolver) {
		self.resolver = resolver
        self.usersManager = resolver.resolve(UsersManager.self)!
        self.apiService = resolver.resolve(ApiService.self)
        self.apiService?.authDelegate = self
        
        self.addObservers()
	}
    
    func loadConversation(request: ConversationDetails.Load.Request) {
        self.conversationId = request.id
        
        self.loadConversation(id: request.id)
    }
    
    func reloadConversation() {
        guard let conversationId = self.conversationId else { return }
        
        self.loadConversation(id: conversationId)
    }
    
    func updateMessageStar(request: ConversationDetails.UpdateMessageStar.Request) {
        guard let userId = self.activeUserId else { return }
        
        var service: MessageOpsProcessing = self.resolver.resolve(MessageOpsProcessing.self, argument: userId)!
        service.delegate = self
        service.label(messageIds: [request.id], label: MailboxSidebar.Item.starred.id, apply: request.isOn)
        
        self.refreshMessage(id: request.id)
        
        // Check if the conversation itself should be starred/unstarred
        self.checkConversationStar()
    }
    
    func updateConversationStar(request: ConversationDetails.UpdateConversationStar.Request) {
        guard let userId = self.activeUserId, let id = self.conversationId else { return }
        
        var service: ConversationOpsProcessing = self.resolver.resolve(ConversationOpsProcessing.self, argument: userId)!
        service.delegate = self
        service.label(conversationIds: [id], label: MailboxSidebar.Item.starred.id, apply: request.isOn, includingMessages: true)
        
        // Dispatch notification for other sections (e.g. list of conversations)
        // This worker will react to this notification as well
        let notification: Conversations.Notifications.ConversationUpdate = Conversations.Notifications.ConversationUpdate(conversationId: id)
        NotificationCenter.default.post(notification)
    }
    
    func processMessageClick(request: ConversationDetails.MessageClick.Request) {
        guard let message = self.conversation?.messages.first(where: { $0.id == request.id }) else { return }
        
        // Message is a draft, show composer
        if message.isDraft {
            // todo implement composer
            return
        }
        
        // Message is expanded, collapse it
        if message.isExpanded {
            message.isExpanded = false
            
            message.contents = nil
            
            let response: ConversationDetails.MessageContentCollapsed.Response = ConversationDetails.MessageContentCollapsed.Response(messageId: request.id)
            self.delegate?.conversationMessageBodyCollapse(response: response)
        }
        // Load the content
        else {
            message.isExpanded = true
            
            let response: ConversationDetails.MessageContentLoadDidBegin.Response = ConversationDetails.MessageContentLoadDidBegin.Response(id: request.id)
            self.delegate?.conversationMessageBodyLoadDidBegin(response: response)
            
            self.loadBody(for: message)
        }
    }
    
    func retryMessageContentLoad(request: ConversationDetails.RetryMessageContentLoad.Request) {
        guard let message = self.conversation?.messages.first(where: { $0.id == request.id }) else { return }
        
        self.loadBody(for: message)
    }
    
    //
    // MARK: - Auth delegate
    //
    
    func onForceUpgrade() {
        //
    }
    
    func sessionDidRevoke() {
        //
    }
    
    func authCredentialDidRefresh() {
        self.usersManager.save()
    }
    
    //
    // MARK: - Conversation ops delegate
    //
    
    func labelsDidUpdateForConversations(ids: [String], labelId: String) {
        // todo refresh
    }
    
    //
    // MARK: - Message ops processing delegate
    //
    
    func labelsDidUpdateForMessages(ids: [String], labelId: String) {
        // todo refresh
    }
    
    //
    // MARK: - Private
    //
    
    private func addObservers() {
        self.conversationUpdateObserver = NotificationCenter.default.addObserver(forType: Conversations.Notifications.ConversationUpdate.self, object: nil, queue: .main, using: { [weak self] notification in
            guard let weakSelf = self, let conversationId = notification?.conversationId else { return }
            
            weakSelf.refreshConversation(id: conversationId)
        })
    }
    
    private func loadConversation(id: String) {
        guard let user = self.usersManager.activeUser else {
            fatalError("Unexpected application state.")
        }
        
        let conversationsDb: ConversationsDatabaseManaging = self.resolver.resolve(ConversationsDatabaseManaging.self)!
        
        guard let conversationObject = conversationsDb.loadConversation(id: id) else { return }
        
        let hasCachedMessages: Bool = conversationObject.messages.count > 0
        
        // If we have cached messages, provide those for now
        if hasCachedMessages {
            self.conversation = self.getConversationWithMessages(conversationObject)
            let response: ConversationDetails.Load.Response = ConversationDetails.Load.Response(conversation: self.conversation!)
            self.delegate?.conversationDidLoad(response: response)
        }
        
        // Also fetch messages for the conversation from the server
        self.auth = user.auth
        let userId: String = user.userId
        
        let request = ConversationByIdRequest(conversationId: id)
        self.apiService?.request(request, completion: { (response: ConversationByIdResponse) in
            if let conversation = response.conversation, let messages = response.messages {
                // Save conversation
                conversationsDb.saveConversations([conversation], forUser: userId) {
                    // Save conversation messages
                    let messagesDb: MessagesDatabaseManaging = self.resolver.resolve(MessagesDatabaseManaging.self)!
                    messagesDb.saveMessages(messages, forUser: userId) {
                        // Make sure we are still showing the conversation we requested
                        guard self.conversationId == id else { return }
                        
                        self.conversation = self.getConversationWithMessages(conversationObject)
                        let response: ConversationDetails.Load.Response = ConversationDetails.Load.Response(conversation: self.conversation!)
                        self.delegate?.conversationDidLoad(response: response)
                    }
                }
            } else {
                // Make sure we are still showing the conversation we requested
                guard self.conversationId == id else { return }
                
                self.conversation = self.getConversationWithMessages(conversationObject)
                let response: ConversationDetails.LoadError.Response = ConversationDetails.LoadError.Response(conversation: self.conversation!, hasCachedMessages: hasCachedMessages)
                self.delegate?.conversationLoadDidFail(response: response)
            }
        })
    }
    
    private func getConversationWithMessages(_ conversation: Conversation) -> ConversationDetails.Conversation.Response {
        let model: Conversations.Conversation.Response = self.getConversation(conversation)
        
        let messageModels: [Messages.Message.Response]
        
        if let messages = conversation.messages.allObjects as? [Message], !messages.isEmpty {
            messageModels = messages.map { self.getMessage($0) }.sorted(by: { m1, m2 in
                return m1.time.date < m2.time.date
            })
        } else {
            messageModels = []
        }
        
        return ConversationDetails.Conversation.Response(conversation: model, messages: messageModels)
    }
    
    private func refreshMessage(id: String) {
        let db: MessagesDatabaseManaging = self.resolver.resolve(MessagesDatabaseManaging.self)!
        
        guard let messageObject = db.loadMessage(id: id) else { return }
        
        let message: Messages.Message.Response = self.getMessage(messageObject)
        let response: ConversationDetails.UpdateMessage.Response = ConversationDetails.UpdateMessage.Response(message: message)
        self.delegate?.conversationMessageDidUpdate(response: response)
    }
    
    private func checkConversationStar() {
        guard let id = self.conversationId, let userId = self.activeUserId else { return }
        
        let db: ConversationsDatabaseManaging = self.resolver.resolve(ConversationsDatabaseManaging.self)!
        
        guard let conversation = db.loadConversation(id: id), let messages = conversation.messages as? Set<Message> else { return }
        
        let isStarred: Bool = conversation.contains(label: .starred)
        var shouldBeStarred: Bool = false
        for message in messages {
            if message.contains(label: .starred) {
                shouldBeStarred = true
                break
            }
        }
        
        var updatedConversation: Conversation?
        
        // Remove star if is starred and should NOT be starred
        if isStarred && !shouldBeStarred {
            updatedConversation = db.updateLabel(conversationIds: [id], label: MailboxSidebar.Item.starred.id, apply: false, includingMessages: false, userId: userId)?.first
        }
        // Add star if is NOT starred and should be starred
        else if !isStarred && shouldBeStarred {
            updatedConversation = db.updateLabel(conversationIds: [id], label: MailboxSidebar.Item.starred.id, apply: true, includingMessages: false, userId: userId)?.first
        }
        
        if updatedConversation != nil {
            // Dispatch notification for other sections (e.g. list of conversations)
            // This worker will react to this notification as well
            let notification: Conversations.Notifications.ConversationUpdate = Conversations.Notifications.ConversationUpdate(conversationId: id)
            NotificationCenter.default.post(notification)
        }
    }
    
    private func refreshConversation(id: String) {
        guard self.conversationId == id else { return }
        
        let db: ConversationsDatabaseManaging = self.resolver.resolve(ConversationsDatabaseManaging.self)!
        
        guard let conversation = db.loadConversation(id: id) else { return }
        
        self.refreshConversation(conversation)
    }
    
    private func refreshConversation(_ conversation: Conversation) {
        // Track expanded messages
        var expandedMessages: [String: Bool] = [:]
        
        if let messages = self.conversation?.messages {
            for message in messages {
                expandedMessages[message.id] = message.isExpanded
            }
        }
        
        // Parse the new conversation
        self.conversation = self.getConversationWithMessages(conversation)
        
        // Restore expanded flags on messages
        for message in self.conversation!.messages {
            message.isExpanded = expandedMessages[message.id] ?? false
        }
        
        let response = ConversationDetails.UpdateConversation.Response(conversation: self.conversation!)
        self.delegate?.conversationDidUpdate(response: response)
    }
    
    //
    // MARK: - Message body
    //
    
    private func loadBody(for message: Messages.Message.Response) {
        let messageId: String = message.id
        
        // Check if we have the body loaded
        if let body = message.body {
            self.processEncryptedBody(body, messageId: messageId)
        }
        // Load the body
        else {
            self.loadMessageBody(messageId: messageId) { body in
                if let body = body {
                    self.updateMessageBody(body, messageId: messageId)
                    self.processEncryptedBody(body, messageId: messageId)
                } else {
                    self.dispatchMessageBodyError(.load, messageId: messageId)
                }
            }
        }
    }
    
    private func loadMessageBody(messageId: String, completion: @escaping (String?) -> Void) {
        guard let userId = self.usersManager.activeUser?.userId else {
            fatalError("Unexpected application state.")
        }
        
        // Load message body
        let worker: MessageBodyLoading = self.resolver.resolve(MessageBodyLoading.self, argument: self.apiService!)!
        worker.load(messageId: messageId, forUser: userId) { body in
            completion(body)
        }
    }
    
    private func processEncryptedBody(_ body: String, messageId: String) {
        guard let decrypted = self.decryptMessageBody(body, messageId: messageId),
              let user = self.usersManager.activeUser else {
            self.dispatchMessageBodyError(.decryption, messageId: messageId)
            return
        }

        self.dispatchMessageBody(decrypted, messageId: messageId)
        
        let worker: MessageInlineAttachmentDecrypting = self.resolver.resolve(MessageInlineAttachmentDecrypting.self, argument: self.apiService!)!
        worker.decryptInlineAttachments(inBody: decrypted, messageId: messageId, user: user) { newBody in
            if let body = newBody {
                self.dispatchMessageBody(body, messageId: messageId)
            }
        }
    }
    
    private func decryptMessageBody(_ body: String, messageId: String) -> String? {
        guard let user = self.usersManager.activeUser,
              let message = self.getMessageModel(id: messageId) else { return nil }
        
        let decryptor: MessageBodyDecrypting = self.resolver.resolve(MessageBodyDecrypting.self)!
        
        return decryptor.decrypt(message: message, user: user)
    }
    
    private func updateMessageBody(_ body: String, messageId: String) {
        guard let message = self.getMessageModel(id: messageId) else { return }
        
        message.body = body
    }
    
    private func dispatchMessageBody(_ body: String, messageId: String) {
        guard let message = self.getMessageModel(id: messageId) else { return }
        
        let contents: Messages.Message.Contents.Response
        
        if let existingContents = message.contents {
            let webContents: WebContents = WebContents(body: body, remoteContentMode: existingContents.contents.remoteContentMode)
            contents = Messages.Message.Contents.Response(contents: webContents, loader: existingContents.loader)
        } else {
            let webContents: WebContents = WebContents(body: body, remoteContentMode: .disallowed)
            let loader: WebContentsSecureLoader = HTTPRequestSecureLoader(addSpacerIfNeeded: false)
            contents = Messages.Message.Contents.Response(contents: webContents, loader: loader)
        }
        
        message.contents = contents
        
        guard message.isExpanded else { return }
        
        let response: ConversationDetails.MessageContentLoaded.Response = ConversationDetails.MessageContentLoaded.Response(messageId: messageId, contents: contents)
        self.delegate?.conversationMessageBodyDidLoad(response: response)
    }
    
    private func dispatchMessageBodyError(_ type: ConversationDetails.MessageContentError, messageId: String) {
        let response: ConversationDetails.MessageContentError.Response = ConversationDetails.MessageContentError.Response(type: type, messageId: messageId)
        self.delegate?.conversationMessageBodyLoadDidFail(response: response)
    }
    
    private func getMessageModel(id: String) -> Messages.Message.Response? {
        return self.conversation?.messages.first(where: { $0.id == id })
    }

}
