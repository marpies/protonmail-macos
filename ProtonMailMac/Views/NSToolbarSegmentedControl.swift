//
//  NSToolbarSegmentedControl.swift
//  ProtonMailMac
//
//  Created by Marcel Piešťanský on 13.10.2021.
//  Copyright © 2021 marpies. All rights reserved.
//

import Cocoa

protocol NSToolbarSegmentedControlDelegate: AnyObject {
    func toolbarGroupSegmentDidClick(id: NSToolbarItem.Identifier)
}

/// Handles click events on segments used in an `NSToolbar`.
/// Makes things simpler than using the `NSSegmentedControl` directly.
class NSToolbarSegmentedControl: NSSegmentedControl {

    var items: [NSToolbarItem.Identifier]?
    
    weak var delegate: NSToolbarSegmentedControlDelegate?
    
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
        self.action = #selector(self.segmentDidTap)
    }
    
    @objc private func segmentDidTap() {
        guard self.selectedSegment >= 0, let items = self.items, self.selectedSegment < items.count else { return }
        
        let id: NSToolbarItem.Identifier = items[self.selectedSegment]
        
        self.delegate?.toolbarGroupSegmentDidClick(id: id)
    }
    
}
