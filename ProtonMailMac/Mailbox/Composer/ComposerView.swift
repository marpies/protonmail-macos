//
//  ComposerView.swift
//  ProtonMailMac
//
//  Created by Marcel Piešťanský on 26.11.2021.
//  Copyright (c) 2021 marpies. All rights reserved.
//

import AppKit

protocol ComposerViewDelegate: AnyObject {
    //
}

class ComposerView: NSView {
    
    weak var delegate: ComposerViewDelegate?
    
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
    
    func displayInitialData(viewModel: Composer.Init.ViewModel) {
        
    }
    
    //
    // MARK: - Private
    //
    
    private func setupView() {
        
    }

}
