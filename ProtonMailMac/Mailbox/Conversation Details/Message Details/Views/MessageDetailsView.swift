//
//  MessageDetailsView.swift
//  ProtonMailMac
//
//  Created by Marcel Piešťanský on 17.09.2021.
//  Copyright © 2021 marpies. All rights reserved.
//

import Foundation
import AppKit
import SnapKit

protocol MessageDetailsViewDelegate: AnyObject {
    func messageDetailDidClick(messageId: String)
    func messageFavoriteStatusDidChange(messageId: String, isOn: Bool)
}

class MessageDetailsView: NSView, MessageDetailsHeaderViewDelegate {
    
    private let headerView: MessageDetailsHeaderView = MessageDetailsHeaderView()
    
    private(set) var messageId: String?
    
    weak var delegate: MessageDetailsViewDelegate?
    
    init() {
        super.init(frame: .zero)
        
        self.setupView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func updateLayer() {
        super.updateLayer()
        
        self.layer?.backgroundColor = NSColor.controlAlternatingRowBackgroundColors.last?.cgColor
        self.layer?.borderColor = NSColor.separatorColor.cgColor
    }
    
    //
    // MARK: - Public
    //
    
    func update(viewModel: Messages.Message.ViewModel) {
        self.messageId = viewModel.id
        
        self.headerView.update(viewModel: viewModel.header)
    }
    
    //
    // MARK: - Header delegate
    //
    
    func messageHeaderViewDidClick() {
        guard let messageId = self.messageId else { return }
        
        self.delegate?.messageDetailDidClick(messageId: messageId)
    }
    
    func imageButtonDidSelect(_ button: ImageButton) {
        guard let messageId = self.messageId else { return }
        
        self.delegate?.messageFavoriteStatusDidChange(messageId: messageId, isOn: true)
    }
    
    func imageButtonDidDeselect(_ button: ImageButton) {
        guard let messageId = self.messageId else { return }
        
        self.delegate?.messageFavoriteStatusDidChange(messageId: messageId, isOn: false)
    }
    
    //
    // MARK: - Private
    //
    
    private func setupView() {
        self.wantsLayer = true
        self.layer?.borderWidth = 1
        self.layer?.cornerRadius = 4
        
        self.headerView.with { view in
            view.delegate = self
            self.addSubview(view)
            view.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
        }
    }
    
}
