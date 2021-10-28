//
//  NSMenuButton.swift
//  ProtonMailMac
//
//  Created by Marcel Piešťanský on 28.10.2021.
//  Copyright © 2021 marpies. All rights reserved.
//

import Cocoa

protocol NSMenuButtonDelegate: AnyObject {
    func buttonDidClick(_ button: NSMenuButton)
}

/// Subclass of NSButton that pops up NSMenu when clicked.
/// The `target` and `action` properties must not be set.
/// Use the `delegate` to handle click events.
class NSMenuButton: NSButton {
    
    var menuOffset: NSPoint = NSPoint(x: 4, y: 4)
    
    weak var delegate: NSMenuButtonDelegate?

    init() {
        super.init(frame: .zero)
        
        self.setupView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    //
    // MARK: - Private
    //
    
    private func setupView() {
        self.target = self
        self.action = #selector(self.didClick)
    }
    
    @objc private func didClick() {
        self.menu?.popUp(positioning: nil, at: NSPoint(x: self.menuOffset.x, y: self.bounds.height + self.menuOffset.y), in: self)
        
        self.delegate?.buttonDidClick(self)
    }
    
}
