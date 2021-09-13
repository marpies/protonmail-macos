//
//  MessagesErrorView.swift
//  ProtonMailMac
//
//  Created by Marcel Piešťanský on 10.09.2021.
//  Copyright © 2021 marpies. All rights reserved.
//

import Foundation
import AppKit

protocol MessagesErrorViewDelegate: AnyObject {
    func errorViewButtonDidTap()
}

class MessagesErrorView: NSView {
    
    private let label: NSTextField = NSTextField.asLabel
    private let button: NSButton = NSButton()
    
    weak var delegate: MessagesErrorViewDelegate?
    
    init() {
        super.init(frame: .zero)
        
        self.setupView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func updateLayer() {
        super.updateLayer()
        
        self.layer?.backgroundColor = NSColor.systemBlue.cgColor
    }
    
    func update(viewModel: Messages.LoadError.ViewModel) {
        self.label.stringValue = viewModel.message
        self.button.title = viewModel.button
    }
    
    //
    // MARK: - Private
    //
    
    private func setupView() {
        self.wantsLayer = true
        self.layer?.cornerRadius = 4
        
        self.label.with { label in
            label.lineBreakMode = .byWordWrapping
            label.setPreferredFont(style: .body)
            label.alignment = .center
            label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
            self.addSubview(label)
            label.snp.makeConstraints { make in
                make.leading.trailing.equalToSuperview().inset(8)
                make.top.equalToSuperview().offset(16)
            }
        }
        
        self.button.with { button in
            button.controlSize = .regular
            button.bezelStyle = .rounded
            button.target = self
            button.action = #selector(self.buttonDidTap)
            button.setContentCompressionResistancePriority(.required, for: .vertical)
            self.addSubview(button)
            button.snp.makeConstraints { make in
                make.top.equalTo(self.label.snp.bottom).offset(8)
                make.centerX.equalToSuperview()
                make.bottom.equalToSuperview().inset(16)
            }
        }
    }
    
    @objc private func buttonDidTap() {
        self.delegate?.errorViewButtonDidTap()
    }
    
}