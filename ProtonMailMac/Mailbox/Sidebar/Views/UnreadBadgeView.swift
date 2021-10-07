//
//  UnreadBadgeView.swift
//  ProtonMailMac
//
//  Created by Marcel Piešťanský on 07.10.2021.
//  Copyright © 2021 marpies. All rights reserved.
//

import Cocoa

class UnreadBadgeView: NSView {
    
    private let label: NSTextField = NSTextField.asLabel
    
    init() {
        super.init(frame: .zero)
        
        self.translatesAutoresizingMaskIntoConstraints = false
        self.setupView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func updateLayer() {
        super.updateLayer()
        
        self.layer?.backgroundColor = NSColor.controlAccentColor.cgColor
        self.layer?.cornerRadius = self.bounds.height / 2
    }
    
    func update(title: String) {
        self.label.stringValue = title
    }
    
    //
    // MARK: - Private
    //
    
    private func setupView() {
        self.wantsLayer = true
        self.label.with { label in
            label.setPreferredFont(style: .subheadline)
            label.textColor = .labelColor
            label.setContentCompressionResistancePriority(.required, for: .horizontal)
            label.setContentCompressionResistancePriority(.required, for: .vertical)
            label.setContentHuggingPriority(.required, for: .horizontal)
            label.alignment = .center
            self.addSubview(label)
            label.snp.makeConstraints { make in
                make.left.right.equalToSuperview().inset(2)
                make.top.bottom.equalToSuperview().inset(2)
            }
        }
    }
    
}
