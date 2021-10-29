//
//  ConversationsOverviewView.swift
//  ProtonMailMac
//
//  Created by Marcel Piešťanský on 29.10.2021.
//  Copyright © 2021 marpies. All rights reserved.
//

import Cocoa

class ConversationsOverviewView: NSStackView {
    
    private let titleLabel: NSTextField = NSTextField.asLabel
    private let messageLabel: NSTextField = NSTextField.asLabel
    private let iconView: NSImageView = NSImageView()

    init() {
        super.init(frame: .zero)
        
        self.setupView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func update(viewModel: ConversationDetails.Overview.ViewModel) {
        self.titleLabel.stringValue = viewModel.title
        self.messageLabel.stringValue = viewModel.message
        
        if #available(macOS 11.0, *) {
            let config = NSImage.SymbolConfiguration(pointSize: 30, weight: .semibold)
            self.iconView.image = NSImage(systemSymbolName: viewModel.icon, accessibilityDescription: nil)?.withSymbolConfiguration(config)
            self.iconView.contentTintColor = viewModel.color
        } else {
            // todo fallback icon
        }
    }
    
    //
    // MARK: - Private
    //
    
    private func setupView() {
        self.orientation = .vertical
        self.spacing = 24
        
        // Icon with title
        NSStackView().with { stack in
            stack.orientation = .horizontal
            stack.spacing = 16
            self.addArrangedSubview(stack)
            
            self.titleLabel.setPreferredFont(style: .largeTitle)
            self.titleLabel.textColor = .labelColor
            stack.addArrangedSubview(self.iconView)
            stack.addArrangedSubview(self.titleLabel)
        }
        
        // Message
        self.messageLabel.setPreferredFont(style: .body)
        self.messageLabel.textColor = .secondaryLabelColor
        self.addArrangedSubview(self.messageLabel)
        
    }
    
}
