//
//  MessageDetailsView.swift
//  ProtonMailMac
//
//  Created by Marcel Piešťanský on 05.09.2021.
//  Copyright (c) 2021 marpies. All rights reserved.
//

import AppKit

protocol MessageDetailsViewDelegate: AnyObject {
    //
}

class MessageDetailsView: NSView {
    
    weak var delegate: MessageDetailsViewDelegate?
    
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
    
    func displayData(viewModel: MessageDetails.Init.ViewModel) {
        
    }
    
    //
    // MARK: - Private
    //
    
    private func setupView() {
        NSTextField.asLabel.with { label in
            label.setPreferredFont(style: .title2)
            label.stringValue = "Message details"
            label.textColor = .labelColor
            self.addSubview(label)
            label.snp.makeConstraints { make in
                make.center.equalToSuperview()
            }
        }
    }

}
