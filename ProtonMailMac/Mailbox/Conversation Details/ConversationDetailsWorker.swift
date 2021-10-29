//
//  ConversationDetailsWorker.swift
//  ProtonMailMac
//
//  Created by Marcel Piešťanský on 17.09.2021.
//  Copyright (c) 2021 marpies. All rights reserved.
//

import Foundation
import Swinject
import AppKit

protocol ConversationDetailsWorkerDelegate: AnyObject {
    func overviewDidLoad(response: ConversationDetails.Overview.Response)
    func conversationLoadDidBegin()
    func conversationDidLoad(response: ConversationDetails.Load.Response)
    func conversationLoadDidFail(response: ConversationDetails.LoadError.Response)
    func conversationMessageDidUpdate(response: ConversationDetails.UpdateMessage.Response)
    func conversationDidUpdate(response: ConversationDetails.UpdateConversation.Response)
    func conversationMessageBodyLoadDidBegin(response: ConversationDetails.MessageContentLoadDidBegin.Response)
    func conversationMessageBodyDidLoad(response: ConversationDetails.MessageContentLoaded.Response)
    func conversationMessageBodyCollapse(response: ConversationDetails.MessageContentCollapsed.Response)
    func conversationMessageBodyLoadDidFail(response: ConversationDetails.MessageContentError.Response)
    func conversationMessageRemoteContentBoxShouldAppear(response: ConversationDetails.DisplayRemoteContentBox.Response)
    func conversationMessageRemoteContentBoxShouldDisappear(response: ConversationDetails.RemoveRemoteContentBox.Response)
}

class ConversationDetailsWorker: AuthCredentialRefreshing, MessageToModelConverting, ConversationToModelConverting, MessageBodyRemoteContentChecking,
                                 MessageOpsProcessingDelegate, ConversationOpsProcessingDelegate, DefaultConversationMessageSelecting, ConversationLabelStatusChecking,
                                 LabelToSidebarItemParsing {

	private let resolver: Resolver
    private let usersManager: UsersManager
    
    private(set) var auth: AuthCredential?
    private(set) var apiService: ApiService?
    
    /// Previously loaded converation id.
    private var conversationId: String?
    
    /// Current conversation model.
    private var conversation: ConversationDetails.Conversation.Response?
    
    private var conversationUpdateObserver: NSObjectProtocol?
    private var conversationsUpdateObserver: NSObjectProtocol?
    private var messageUpdateObserver: NSObjectProtocol?
    private var messagesUpdateObserver: NSObjectProtocol?
    
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
    
    func loadLabelOverview(request: ConversationDetails.Overview.Request) {
        let keyValueStore: KeyValueStore = self.resolver.resolve(KeyValueStore.self)!
        
        guard let labelId = keyValueStore.string(forKey: .lastLabelId),
              let numItems = self.getItemsTotalCount(labelId: labelId),
              let label = self.getLabel(forId: labelId) else { return }
        
        let item: MailboxSidebar.Item = self.getSidebarItemKind(response: label)
        var color: NSColor?
        if !label.color.isEmpty {
            color = NSColor(hexColorCode: label.color)
        }
        
        // Cancel active conversation id
        self.conversationId = nil
        
        let response: ConversationDetails.Overview.Response = ConversationDetails.Overview.Response(label: item, numItems: numItems, color: color)
        self.delegate?.overviewDidLoad(response: response)
    }
    
    func loadConversation(request: ConversationDetails.Load.Request) {
        // Do not load the conversation that is already shown
        if let id = self.conversationId, id == request.id {
            return
        }
        
        self.conversationId = request.id
        
        self.loadConversation(id: request.id, expandDefaultMessage: true)
    }
    
    func reloadConversation() {
        guard let conversationId = self.conversationId else { return }
        
        self.loadConversation(id: conversationId, expandDefaultMessage: false)
    }
    
    func updateMessageStar(request: ConversationDetails.UpdateMessageStar.Request) {
        let db: MessagesDatabaseManaging = self.resolver.resolve(MessagesDatabaseManaging.self)!
        
        guard let userId = self.activeUserId, let conversation = db.loadMessage(id: request.id)?.conversation else { return }
        
        // Get starred status before updating
        let isConversationStarred: Bool = conversation.contains(label: .starred)
        
        // Update message's and conversation's label
        var service: MessageOpsProcessing = self.resolver.resolve(MessageOpsProcessing.self, arguments: userId, self.apiService!)!
        service.delegate = self
        service.label(messageIds: [request.id], label: MailboxSidebar.Item.starred.id, apply: request.isOn)
        
        self.refreshMessage(id: request.id)
        
        // Check if the conversation star changed and dispatch notification if needed for other scenes to reflect this change
        self.checkConversationLabel(label: .starred, conversation: conversation, hasLabel: isConversationStarred)
        
        // Dispatch notification for other sections (e.g. list of messages)
        // This worker will react to this notification as well
        let notification: Messages.Notifications.MessageUpdate = Messages.Notifications.MessageUpdate(messageId: request.id)
        notification.post()
    }
    
    func updateConversationStar(request: ConversationDetails.UpdateConversationStar.Request) {
        guard let userId = self.activeUserId, let id = self.conversationId else { return }
        
        var service: ConversationOpsProcessing = self.resolver.resolve(ConversationOpsProcessing.self, argument: userId)!
        service.delegate = self
        service.label(conversationIds: [id], label: MailboxSidebar.Item.starred.id, apply: request.isOn)
        
        let db: ConversationsDatabaseManaging = self.resolver.resolve(ConversationsDatabaseManaging.self)!
        if let conversation = db.loadConversation(id: id), let messages = conversation.messages as? Set<Message> {
            let ids: Set<String> = Set(messages.map { $0.messageID })
            let notification: Messages.Notifications.MessagesUpdate = Messages.Notifications.MessagesUpdate(messageIds: ids)
            notification.post()
        }
        
        // Dispatch notification for other sections (e.g. list of conversations)
        // This worker will react to this notification as well
        let notification: Conversations.Notifications.ConversationUpdate = Conversations.Notifications.ConversationUpdate(conversationId: id)
        notification.post()
    }
    
    func processMessageClick(request: ConversationDetails.MessageClick.Request) {
        guard let message = self.getMessageModel(id: request.id) else { return }
        
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
            self.loadMessage(message)
        }
    }
    
    func retryMessageContentLoad(request: ConversationDetails.RetryMessageContentLoad.Request) {
        guard let message = self.getMessageModel(id: request.id) else { return }
        
        self.loadBody(for: message)
    }
    
    func processRemoteContentButtonClick(request: ConversationDetails.RemoteContentButtonClick.Request) {
        guard let message = self.getMessageModel(id: request.messageId), let body = message.contents?.contents.body else { return }
        
        // Hide the remote content box
        let response: ConversationDetails.RemoveRemoteContentBox.Response = ConversationDetails.RemoveRemoteContentBox.Response(messageId: request.messageId)
        self.delegate?.conversationMessageRemoteContentBoxShouldDisappear(response: response)
        
        // Reload the body with the new content mode
        self.dispatchMessageBody(body, messageId: message.id, remoteContentMode: .allowed)
    }
    
    func processContactMenuItemTap(request: ConversationDetails.ContactMenuItemTap.Request) {
        switch request.id {
        case .copyAddress(let email):
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(email, forType: .string)
        default:
            return
        }
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
        
        self.conversationsUpdateObserver = NotificationCenter.default.addObserver(forType: Conversations.Notifications.ConversationsUpdate.self, object: nil, queue: .main, using: { [weak self] notification in
            guard let weakSelf = self,
                  let id = weakSelf.conversationId,
                  let conversationIds = notification?.conversationIds,
                  conversationIds.contains(id) else { return }
            
            weakSelf.refreshConversation(id: id)
        })
        
        self.messageUpdateObserver = NotificationCenter.default.addObserver(forType: Messages.Notifications.MessageUpdate.self, object: nil, queue: .main, using: { [weak self] notification in
            guard let weakSelf = self, let messageId = notification?.messageId else { return }
            
            weakSelf.refreshMessage(id: messageId)
        })
        
        self.messagesUpdateObserver = NotificationCenter.default.addObserver(forType: Messages.Notifications.MessagesUpdate.self, object: nil, queue: .main, using: { [weak self] notification in
            guard let weakSelf = self,
                  let conversation = weakSelf.conversation,
                  let messageIds = notification?.messageIds else { return }
            
            for message in conversation.messages {
                if messageIds.contains(message.id) {
                    weakSelf.refreshMessage(id: message.id)
                }
            }
        })
    }
    
    private func loadConversation(id: String, expandDefaultMessage: Bool) {
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
        } else {
            self.delegate?.conversationLoadDidBegin()
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
                        
                        self.updateConversationModel(conversationObject)
                        
                        let response: ConversationDetails.Load.Response = ConversationDetails.Load.Response(conversation: self.conversation!)
                        self.delegate?.conversationDidLoad(response: response)
                        
                        // Expand the default message if needed
                        if expandDefaultMessage, let message = self.getDefaultMessage(conversation: self.conversation!) {
                            self.loadMessage(message)
                        }
                    }
                }
            } else {
                // Make sure we are still showing the conversation we requested
                guard self.conversationId == id else { return }
                
                self.updateConversationModel(conversationObject)
                
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
        self.conversation?.updateMessage(message)
        
        let response: ConversationDetails.UpdateMessage.Response = ConversationDetails.UpdateMessage.Response(message: message)
        self.delegate?.conversationMessageDidUpdate(response: response)
    }
    
    private func refreshConversation(id: String) {
        guard self.conversationId == id else { return }
        
        let db: ConversationsDatabaseManaging = self.resolver.resolve(ConversationsDatabaseManaging.self)!
        
        guard let conversation = db.loadConversation(id: id) else { return }
        
        self.refreshConversation(conversation)
    }
    
    private func refreshConversation(_ conversation: Conversation) {
        self.updateConversationModel(conversation)
        
        let response = ConversationDetails.UpdateConversation.Response(conversation: self.conversation!)
        self.delegate?.conversationDidUpdate(response: response)
    }
    
    
    /// Updates the local (memory) conversation model and preserves expanded state of existing messages.
    /// - Parameter conversation: The updated conversation model to read from.
    private func updateConversationModel(_ conversation: Conversation) {
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
    }
    
    //
    // MARK: - Message body
    //
    
    private func loadMessage(_ message: Messages.Message.Response) {
        message.isExpanded = true
        
        let response: ConversationDetails.MessageContentLoadDidBegin.Response = ConversationDetails.MessageContentLoadDidBegin.Response(id: message.id)
        self.delegate?.conversationMessageBodyLoadDidBegin(response: response)
        
        self.loadBody(for: message)
    }
    
    private func loadBody(for message: Messages.Message.Response) {
        let messageId: String = message.id
        
        // Check if we have the body loaded
        if let body = message.body {
            self.processEncryptedBody(body, message: message)
        }
        // Load the body
        else {
            self.loadMessageBody(messageId: messageId) { body in
                if let body = body {
                    self.updateMessageBody(body, messageId: messageId)
                    self.processEncryptedBody(body, message: message)
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
    
    private func processEncryptedBody(_ body: String, message: Messages.Message.Response) {
        guard let decrypted = self.decryptMessageBody(body, messageId: message.id),
              let user = self.usersManager.activeUser else {
            self.dispatchMessageBodyError(.decryption, messageId: message.id)
            return
        }
        
        // Decrypt inline attachments first to avoid displaying email without attachments momentarily
        if message.hasInlineAttachments {
            let worker: MessageInlineAttachmentDecrypting = self.resolver.resolve(MessageInlineAttachmentDecrypting.self, argument: self.apiService!)!
            worker.decryptInlineAttachments(inBody: decrypted, messageId: message.id, user: user) { newBody in
                let body: String = newBody ?? decrypted
                
                self.dispatchMessageBody(body, messageId: message.id)
                self.checkRemoteContent(message: message, rawBody: decrypted)
                self.markMessageAsRead(message)
            }
            return
        }
        
        self.dispatchMessageBody(decrypted, messageId: message.id)
        self.checkRemoteContent(message: message, rawBody: decrypted)
        self.markMessageAsRead(message)
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
    
    private func dispatchMessageBody(_ body: String, messageId: String, remoteContentMode: WebContents.RemoteContentPolicy? = nil) {
        guard let message = self.getMessageModel(id: messageId), message.isExpanded else { return }
        
        // todo default content mode may be allowed as per user settings
        let defaultContentMode: WebContents.RemoteContentPolicy = .disallowed
        let contentMode: WebContents.RemoteContentPolicy = remoteContentMode ?? message.contents?.contents.remoteContentMode ?? defaultContentMode
        let loader: WebContentsSecureLoader = message.contents?.loader ?? HTTPRequestSecureLoader(addSpacerIfNeeded: false)
        let webContents: WebContents = WebContents(body: body, remoteContentMode: contentMode)
        let contents: Messages.Message.Contents.Response = Messages.Message.Contents.Response(contents: webContents, loader: loader)
        
        message.contents = contents
        
        let response: ConversationDetails.MessageContentLoaded.Response = ConversationDetails.MessageContentLoaded.Response(messageId: messageId, contents: contents)
        self.delegate?.conversationMessageBodyDidLoad(response: response)
    }
    
    private func dispatchMessageBodyError(_ type: ConversationDetails.MessageContentError, messageId: String) {
        let response: ConversationDetails.MessageContentError.Response = ConversationDetails.MessageContentError.Response(type: type, messageId: messageId)
        self.delegate?.conversationMessageBodyLoadDidFail(response: response)
    }
    
    //
    // MARK: - Remote content
    //
    
    private func checkRemoteContent(message: Messages.Message.Response, rawBody: String) {
        guard message.isExpanded, let contents = message.contents?.contents else { return }
        
        // See if we already checked for remote content
        if let hasRemoteContent = message.hasRemoteContent {
            if message.isExpanded, hasRemoteContent, contents.remoteContentMode != .allowed {
                self.showRemoteContentBox(onMessage: message)
            }
            return
        }
        
        self.checkHasMessageRemoteContent(body: rawBody, contentPolicy: contents.remoteContentMode) { hasRemoteContent in
            message.hasRemoteContent = hasRemoteContent
            
            guard message.isExpanded, hasRemoteContent else { return }
            
            self.showRemoteContentBox(onMessage: message)
        }
    }
    
    private func showRemoteContentBox(onMessage message: Messages.Message.Response) {
        let response: ConversationDetails.DisplayRemoteContentBox.Response = ConversationDetails.DisplayRemoteContentBox.Response(messageId: message.id)
        self.delegate?.conversationMessageRemoteContentBoxShouldAppear(response: response)
    }
    
    //
    // MARK: - Mark as read
    //
    
    private func markMessageAsRead(_ message: Messages.Message.Response) {
        guard !message.isRead else { return }
        
        let db: MessagesDatabaseManaging = self.resolver.resolve(MessagesDatabaseManaging.self)!
        
        guard let userId = self.activeUserId, let conversation = db.loadMessage(id: message.id)?.conversation else { return }
        
        // Get unread status before updating
        let isConversationUnread: Bool = conversation.numUnread.intValue > 0
        
        // Update unread status of the message
        var service: MessageOpsProcessing = self.resolver.resolve(MessageOpsProcessing.self, arguments: userId, self.apiService!)!
        service.delegate = self
        
        let success: Bool = service.mark(messageIds: [message.id], unread: false)
        guard success else { return }
        
        self.refreshMessage(id: message.id)
        
        // Check if the conversation itself should be marked as read
        self.checkConversationRead(conversationId: conversation.conversationID, isUnread: isConversationUnread)
        
        let notification: Messages.Notifications.MessageUpdate = Messages.Notifications.MessageUpdate(messageId: message.id)
        notification.post()
    }
    
    private func checkConversationRead(conversationId: String, isUnread: Bool) {
        guard let userId = self.activeUserId else { return }
        
        let db: ConversationsDatabaseManaging = self.resolver.resolve(ConversationsDatabaseManaging.self)!
        
        guard let conversation = db.loadConversation(id: conversationId), let messages = conversation.messages as? Set<Message> else { return }
        
        var shouldBeUnread: Bool = false
        for message in messages {
            if message.unRead {
                shouldBeUnread = true
                break
            }
        }
        
        var updatedConversation: Conversation?
        
        // Mark as read if unread and should NOT be unread
        if isUnread && !shouldBeUnread {
            updatedConversation = db.updateUnread(conversationIds: [conversationId], unread: false, userId: userId)?.first
        }
        // Mark as unread if read and should be unread
        else if !isUnread && shouldBeUnread {
            updatedConversation = db.updateUnread(conversationIds: [conversationId], unread: true, userId: userId)?.first
        }
        
        if updatedConversation != nil {
            // Dispatch notification for other sections (e.g. list of conversations)
            // This worker will react to this notification as well
            let notification: Conversations.Notifications.ConversationUpdate = Conversations.Notifications.ConversationUpdate(conversationId: conversationId)
            NotificationCenter.default.post(notification)
        }
    }
    
    //
    // MARK: - Helpers
    //
    
    private func getMessageModel(id: String) -> Messages.Message.Response? {
        return self.conversation?.messages.first(where: { $0.id == id })
    }
    
    private func getLabel(forId id: String) -> Label? {
        let db: LabelsDatabaseManaging = self.resolver.resolve(LabelsDatabaseManaging.self)!
        
        return db.getLabel(byId: id)
    }
    
    private func getItemsTotalCount(labelId: String) -> Int? {
        guard let userId = self.activeUserId else { return nil }
        
        let db: LabelUpdateDatabaseManaging = self.resolver.resolve(LabelUpdateDatabaseManaging.self)!
        return db.getTotalCount(for: labelId, userId: userId)
    }

}
