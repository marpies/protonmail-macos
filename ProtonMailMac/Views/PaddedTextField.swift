//
//  PaddedTextField.swift
//  ProtonMailMac
//
//  Created by Marcel Piešťanský on 25.08.2021.
//  Copyright © 2021 marpies. All rights reserved.
//

import Foundation
import AppKit

class PaddedTextField: NSTextField {
    
    override class var cellClass: AnyClass? {
        get {
            return PaddedTextFieldCell.self
        }
        set {
            NSTextField.cellClass = newValue
        }
    }
    
    var observation: NSKeyValueObservation?
    
    init() {
        super.init(frame: .zero)
        
        self.isBezeled = false
        self.isBordered = false
        self.isEditable = true
        self.isSelectable = true
        
        self.wantsLayer = true
        
        self.layer?.borderWidth = 1
        self.layer?.borderColor = NSColor.separatorColor.cgColor
        self.layer?.cornerRadius = 4
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

fileprivate class PaddedTextFieldCell: NSTextFieldCell {
    
    private static let padding = CGSize(width: 8.0, height: 8.0)
    
    override func cellSize(forBounds rect: NSRect) -> NSSize {
        var size = super.cellSize(forBounds: rect)
        size.height += (PaddedTextFieldCell.padding.height * 2)
        return size
    }
    
    override func titleRect(forBounds rect: NSRect) -> NSRect {
        return rect.insetBy(dx: PaddedTextFieldCell.padding.width, dy: PaddedTextFieldCell.padding.height)
    }
    
    override func edit(withFrame rect: NSRect, in controlView: NSView, editor textObj: NSText, delegate: Any?, event: NSEvent?) {
        let insetRect = rect.insetBy(dx: PaddedTextFieldCell.padding.width, dy: PaddedTextFieldCell.padding.height)
        super.edit(withFrame: insetRect, in: controlView, editor: textObj, delegate: delegate, event: event)
    }
    
    override func select(withFrame rect: NSRect, in controlView: NSView, editor textObj: NSText, delegate: Any?, start selStart: Int, length selLength: Int) {
        let insetRect = rect.insetBy(dx: PaddedTextFieldCell.padding.width, dy: PaddedTextFieldCell.padding.height)
        super.select(withFrame: insetRect, in: controlView, editor: textObj, delegate: delegate, start: selStart, length: selLength)
    }
    
    override func drawInterior(withFrame cellFrame: NSRect, in controlView: NSView) {
        let insetRect = cellFrame.insetBy(dx: PaddedTextFieldCell.padding.width, dy: PaddedTextFieldCell.padding.height)
        super.drawInterior(withFrame: insetRect, in: controlView)
    }
    
}
