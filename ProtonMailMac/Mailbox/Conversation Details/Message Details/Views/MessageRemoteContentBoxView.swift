//
//  MessageRemoteContentBoxView.swift
//  ProtonMailMac
//
//  Created by Marcel Piešťanský on 26.09.2021.
//  Copyright © 2021 marpies. All rights reserved.
//

import Foundation
import AppKit
import SnapKit

protocol MessageRemoteContentBoxViewDelegate: AnyObject {
    func messageRemoteContentButtonDidClick()
}

class MessageRemoteContentBoxView: NSView {
    
    private let messageLabel: NSTextField = NSTextField.asLabel
    private let button: NSButton = NSButton()
    
    weak var delegate: MessageRemoteContentBoxViewDelegate?
    
    init() {
        super.init(frame: .zero)
        
        self.setupView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    //
    // MARK: - Public
    //
    
    func update(viewModel: Messages.Message.RemoteContentBox.ViewModel) {
        self.messageLabel.stringValue = viewModel.message
        self.button.title = viewModel.button
    }
    
    //
    // MARK: - Private
    //
    
    private func setupView() {
        NSView().with { border in
            border.wantsLayer = true
            border.layer?.backgroundColor = NSColor.separatorColor.cgColor
            self.addSubview(border)
            border.snp.makeConstraints { make in
                make.left.right.top.equalToSuperview()
                make.height.equalTo(1)
            }
            
            NSStackView().with { stack in
                stack.distribution = .fill
                stack.orientation = .horizontal
                self.addSubview(stack)
                stack.snp.makeConstraints { make in
                    make.top.equalTo(border.snp.bottom).offset(8)
                    make.left.right.equalToSuperview().inset(16)
                    make.bottom.equalToSuperview().inset(8)
                }
                
                self.messageLabel.with { label in
                    label.setPreferredFont(style: .caption1)
                    label.textColor = .labelColor
                    label.setContentHuggingPriority(.defaultLow, for: .horizontal)
                    label.setContentCompressionResistancePriority(.required, for: .vertical)
                    stack.addArrangedSubview(label)
                }
                
                self.button.with { button in
                    button.bezelStyle = .rounded
                    button.controlSize = .small
                    button.setContentHuggingPriority(.defaultHigh, for: .horizontal)
                    button.setContentCompressionResistancePriority(.required, for: .vertical)
                    button.target = self
                    button.action = #selector(self.buttonDidClick)
                    stack.addArrangedSubview(button)
                }
            }
        }
    }
    
    @objc private func buttonDidClick() {
        self.delegate?.messageRemoteContentButtonDidClick()
    }
    
}
