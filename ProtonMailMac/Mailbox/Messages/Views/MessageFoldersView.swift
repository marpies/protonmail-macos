//
//  MessageFoldersView.swift
//  ProtonMailMac
//
//  Created by Marcel Piešťanský on 10.09.2021.
//  Copyright © 2021 marpies. All rights reserved.
//

import Cocoa
import SnapKit

class MessageFoldersView: NSStackView {

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
    
    func update(viewModel: [Messages.Folder.ViewModel]) {
        for view in self.arrangedSubviews {
            view.removeFromSuperview()
        }
        
        if #available(macOS 11.0, *) {
            for model in viewModel {
                guard let image = NSImage(systemSymbolName: model.icon, accessibilityDescription: nil) else { continue }
                
                let icon = NSImageView(image: image)
                
                icon.contentTintColor = model.color ?? .secondaryLabelColor
                
                icon.toolTip = model.title
                
                self.addArrangedSubview(icon)
                icon.snp.makeConstraints { make in
                    make.size.equalTo(20)
                }
            }
        } else {
            // todo font icons
        }
    }
    
    //
    // MARK: - Private
    //
    
    private func setupView() {
        self.orientation = .horizontal
        self.spacing = 0
        self.alignment = .centerY
    }
    
}
