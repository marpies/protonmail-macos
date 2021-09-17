//
//  MessagesWorker.swift
//  ProtonMailMac
//
//  Created by Marcel Piešťanský on 05.09.2021.
//  Copyright (c) 2021 marpies. All rights reserved.
//

import Foundation
import Swinject
import AppKit

protocol MessagesWorkerDelegate: AnyObject {
    
}

class MessagesWorker: MessageOpsProcessingDelegate {

    private let resolver: Resolver
    private let usersManager: UsersManager
    
    /// Date of the last loaded message. Nil if messages have not been loaded yet.
    private var lastMessageTime: Date?
    
    private var messages: [Messages.Message.Response]?
    
    private var activeUserId: String? {
        return self.usersManager.activeUser?.userId
    }
    
    /// The last loaded label. Nil if messages have not been loaded yet.
    var labelId: String?

	weak var delegate: MessagesWorkerDelegate?

    init(resolver: Resolver) {
		self.resolver = resolver
        self.usersManager = resolver.resolve(UsersManager.self)!
	}
    
    func starMessage(request: Messages.StarMessage.Request) {
        guard let userId = self.activeUserId else { return }
        
        var service: MessageOpsProcessing = self.resolver.resolve(MessageOpsProcessing.self, argument: userId)!
        service.delegate = self
        service.label(messageIds: [request.id], label: MailboxSidebar.Item.starred.id, apply: true)
    }
    
    func unstarMessage(request: Messages.UnstarMessage.Request) {
        guard let userId = self.activeUserId else { return }
        
        var service: MessageOpsProcessing = self.resolver.resolve(MessageOpsProcessing.self, argument: userId)!
        service.delegate = self
        service.label(messageIds: [request.id], label: MailboxSidebar.Item.starred.id, apply: false)
    }
    
    //
    // MARK: - Message ops processing delegate
    //
    
    func labelsDidUpdateForMessages(ids: [String], labelId: String) {
        // todo fetch events for label
    }
    
    //
    // MARK: - Private
    //

}
