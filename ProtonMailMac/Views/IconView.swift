//
//  IconView.swift
//  ProtonMailMac
//
//  Created by Marcel Piešťanský on 20.09.2021.
//  Copyright © 2021 marpies. All rights reserved.
//

import Foundation
import AppKit
import SnapKit

class IconView: NSView {
    
    private var imageView: NSImageView?
    private var label: NSTextField?
    
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
    
    func update(icon: String, color: NSColor) {
        if #available(macOS 11.0, *) {
            self.imageView?.contentTintColor = color
            self.imageView?.image = NSImage(systemSymbolName: icon, accessibilityDescription: icon)
        } else {
            self.label?.textColor = color
            self.label?.stringValue = icon
        }
    }
    
    //
    // MARK: - Private
    //
    
    private func setupView() {
        // Use image view for Big Sur and newer
        if #available(macOS 11.0, *) {
            self.imageView = NSImageView().with { view in
                self.addSubview(view)
                view.snp.makeConstraints { make in
                    make.edges.equalToSuperview()
                }
            }
        }
        // Use label (icon font)
        else {
            self.label = NSTextField.asLabel.with { label in
                self.addSubview(label)
                label.snp.makeConstraints { make in
                    make.edges.equalToSuperview()
                }
            }
        }
    }
    
}
