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
        
        for model in viewModel {
            let color: NSColor = model.color ?? .secondaryLabelColor
            
            let icon = IconView()
            icon.toolTip = model.title
            icon.update(icon: model.icon, color: color)
            self.addArrangedSubview(icon)
            icon.snp.makeConstraints { make in
                make.size.equalTo(20)
            }
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
