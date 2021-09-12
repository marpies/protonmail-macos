//
//  MessageLabelView.swift
//  ProtonMailMac
//
//  Created by Marcel Piešťanský on 10.09.2021.
//  Copyright © 2021 marpies. All rights reserved.
//

import Cocoa
import SnapKit

class MessageLabelView: NSView {
    
    private let label: NSTextField = NSTextField.asLabel
    
    var color: NSColor?

    init() {
        super.init(frame: .zero)
        
        self.setupView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func updateLayer() {
        super.updateLayer()
        
        self.layer?.backgroundColor = self.color?.cgColor
        
        if self.bounds.height > 0 {
            self.layer?.cornerRadius = self.bounds.height / 6
        }
    }
    
    //
    // MARK: - Public
    //
    
    func update(viewModel: Messages.Label.ViewModel) {
        self.color = viewModel.color
        self.layer?.borderColor = viewModel.color.cgColor
        self.label.stringValue = viewModel.title
        
        self.label.textColor = viewModel.color.isLight ? .black : .white
        self.toolTip = viewModel.title
    }
    
    //
    // MARK: - Private
    //
    
    private func setupView() {
        self.wantsLayer = true
        
        self.label.with { label in
            label.alphaValue = 0.8
            label.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
            label.setContentCompressionResistancePriority(.defaultHigh, for: .vertical)
            label.setPreferredFont(style: .footnote)
            self.addSubview(label)
            label.snp.makeConstraints { make in
                make.left.right.equalToSuperview().inset(8)
                make.top.bottom.equalToSuperview().inset(2)
            }
        }
    }
    
}
