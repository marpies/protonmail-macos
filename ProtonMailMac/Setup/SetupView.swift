//
//  SetupView.swift
//  ProtonMailMac
//
//  Created by Marcel Piešťanský on 24.08.2021.
//  Copyright (c) 2021 marpies. All rights reserved.
//

import AppKit
import SnapKit

protocol SetupViewDelegate: AnyObject {
    //
}

class SetupView: NSView {
    
    weak var delegate: SetupViewDelegate?
    
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
    
    func displayLaunchContent(viewModel: Setup.LaunchContent.ViewModel) {
        
    }
    
    //
    // MARK: - Private
    //
    
    private func setupView() {
        
    }

}
