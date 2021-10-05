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
    func messageRetryContentLoadButtonDidTap(messageId: String)
    func messageRemoteContentButtonDidClick(messageId: String)
}

class MessageDetailsView: NSView, MessageDetailsHeaderViewDelegate, MessageBodyViewDelegate, MessageRemoteContentBoxViewDelegate {
    
    private let headerView: MessageDetailsHeaderView = MessageDetailsHeaderView()
    private var bodyView: MessageBodyView?
    private var remoteContentView: MessageRemoteContentBoxView?
    
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
    
    func showContentLoading() {
        self.initBodyView()
        self.bodyView?.showLoading()
    }
    
    func showContent(viewModel: Messages.Message.Contents.ViewModel) {
        self.initBodyView()
        self.bodyView?.showContent(viewModel: viewModel)
    }
    
    func showErrorContent(message: String, button: String) {
        self.initBodyView()
        self.bodyView?.showErrorContent(message: message, button: button)
    }
    
    func showRemoteContentBox(viewModel: Messages.Message.RemoteContentBox.ViewModel) {
        if self.remoteContentView == nil {
            self.remoteContentView = MessageRemoteContentBoxView().with { view in
                view.delegate = self
                self.addSubview(view)
                view.snp.makeConstraints { make in
                    make.left.right.equalToSuperview()
                    make.top.equalTo(self.headerView.snp.bottom).priority(.required)
                    make.bottom.equalToSuperview().priority(.high)
                }
            }

            self.updateBodyViewConstraints()
        }

        self.remoteContentView?.update(viewModel: viewModel)
    }
    
    func removeRemoteContentBox() {
        guard let view = self.remoteContentView else { return }
        
        view.removeFromSuperview()
        self.remoteContentView = nil
        
        self.updateBodyViewConstraints()
    }
    
    func removeContentView() {
        self.removeRemoteContentBox()
        
        self.bodyView?.dispose()
        self.bodyView?.removeFromSuperview()
        self.bodyView = nil
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
    // MARK: - Body view delegate
    //
    
    func retryContentLoadButtonDidTap() {
        guard let messageId = self.messageId else { return }
        
        self.delegate?.messageRetryContentLoadButtonDidTap(messageId: messageId)
    }
    
    //
    // MARK: - Remote content box delegate
    //
    
    func messageRemoteContentButtonDidClick() {
        guard let messageId = self.messageId else { return }
        
        self.delegate?.messageRemoteContentButtonDidClick(messageId: messageId)
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
                make.top.left.right.equalToSuperview()
                make.bottom.equalToSuperview().priority(.high)
            }
        }
    }
    
    private func initBodyView() {
        guard self.bodyView == nil else { return }
        
        self.bodyView = MessageBodyView().with { view in
            view.delegate = self
            self.addSubview(view)
        }
        
        self.updateBodyViewConstraints()
    }
    
    private func updateBodyViewConstraints() {
        let topAnchor: NSView = self.remoteContentView ?? self.headerView
        
        self.bodyView?.snp.remakeConstraints { make in
            make.left.right.equalToSuperview()
            make.bottom.equalToSuperview().priority(.required)
            make.top.equalTo(topAnchor.snp.bottom)
        }
    }
    
}
