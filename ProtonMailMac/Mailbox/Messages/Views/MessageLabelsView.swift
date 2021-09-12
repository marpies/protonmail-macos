//
//  MessageLabelsView.swift
//  ProtonMailMac
//
//  Created by Marcel Piešťanský on 10.09.2021.
//  Copyright © 2021 marpies. All rights reserved.
//

import Cocoa

class MessageLabelsView: NSStackView {

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
    
    func update(viewModel: [Messages.Label.ViewModel]) {
        for view in self.subviews {
            view.removeFromSuperview()
        }
        
        for model in viewModel {
            let view = MessageLabelView()
            view.update(viewModel: model)
            self.addArrangedSubview(view)
        }
    }
    
    //
    // MARK: - Private
    //
    
    private func setupView() {
        self.orientation = .horizontal
        self.spacing = 6
    }
    
}
