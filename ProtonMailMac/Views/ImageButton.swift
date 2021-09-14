//
//  ImageButton.swift
//  ProtonMailMac
//
//  Created by Marcel Piešťanský on 14.09.2021.
//  Copyright © 2021 marpies. All rights reserved.
//

import Foundation
import AppKit

protocol ImageButtonDelegate: AnyObject {
    func imageButtonDidSelect(_ button: ImageButton)
    func imageButtonDidDeselect(_ button: ImageButton)
}

class ImageButton: NSButton {
    
    weak var delegate: ImageButtonDelegate?
    
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
        self.isBordered = false
        self.imagePosition = .imageOnly
        self.focusRingType = .none
        self.setButtonType(.toggle)
        
        self.target = self
        self.action = #selector(self.onAction)
        
        // todo catalina and older use font icon
    }
    
    @objc private func onAction() {
        if self.state == .on {
            self.delegate?.imageButtonDidSelect(self)
        } else if self.state == .off {
            self.delegate?.imageButtonDidDeselect(self)
        }
    }
    
}
