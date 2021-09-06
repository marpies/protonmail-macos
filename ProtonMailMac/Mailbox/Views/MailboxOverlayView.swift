//
//  MailboxOverlayView.swift
//  ProtonMailMac
//
//  Created by Marcel Piešťanský on 27.08.2021.
//  Copyright © 2021 marpies. All rights reserved.
//

import Cocoa
import SnapKit

class MailboxOverlayView: NSView {
    
    init() {
        super.init(frame: .zero)
        
        self.setupView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func update(message: String) {
        NSTextField.asLabel.with { label in
            label.setPreferredFont(style: .title1)
            label.stringValue = message
            self.addSubview(label)
            label.snp.makeConstraints { make in
                make.center.equalToSuperview()
            }
        }
    }
    
    override func updateLayer() {
        super.updateLayer()
        
        self.layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor
    }
    
    //
    // MARK: - Private
    //
    
    private func setupView() {
        self.wantsLayer = true
        self.layerContentsRedrawPolicy = .onSetNeedsDisplay
    }
    
}
