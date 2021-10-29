//
//  WrapStackView.swift
//  ProtonMailMac
//
//  Created by Marcel Piešťanský on 28.10.2021.
//  Copyright © 2021 marpies. All rights reserved.
//

import Cocoa

/// View that stacks self-sizing subviews horizontally and wraps to a new line if needed.
class WrapStackView: NSView {
    
    /// Horizontal and vertical spacing between the subviews.
    var spacing: NSPoint = NSPoint.zero
    
    override var isFlipped: Bool {
        return true
    }
    
    override var frame: NSRect {
        didSet {
            if !frame.equalTo(oldValue) {
                self.needsLayout = true
            }
        }
    }

    override func layout() {
        super.layout()
        
        guard !self.subviews.isEmpty else {
            return
        }
        
        var iterator = self.subviews.makeIterator()
        self.enumerateRects { rect in
            iterator.next()?.frame = rect
        }
        
        self.invalidateIntrinsicContentSize()
    }
    
    override var intrinsicContentSize: NSSize {
        if self.subviews.isEmpty || self.bounds.width == 0 {
            return NSSize(width: NSView.noIntrinsicMetric, height: NSView.noIntrinsicMetric)
        }

        var total: NSRect = .zero
        self.enumerateRects { rect in
            total = total.union(rect)
        }

        return NSSize(width: NSView.noIntrinsicMetric, height: total.height)
    }
    
    //
    // MARK: - Private
    //
    
    private func enumerateRects(block: (NSRect) -> Void) {
        let maxWidth: CGFloat = self.subviews.max { v1, v2 in
            return v1.intrinsicContentSize.width > v2.intrinsicContentSize.width
        }?.bounds.width ?? 0
        
        let layoutWidth: CGFloat = max(self.bounds.width, maxWidth)
        var lastX: CGFloat = 0
        var lastY: CGFloat = 0
        var maxHeight: CGFloat = 0
        
        for view in self.subviews {
            let size: NSSize = view.intrinsicContentSize
            let viewWidth: CGFloat = size.width
            let viewHeight: CGFloat = size.height
            
            if viewHeight > maxHeight {
                maxHeight = viewHeight
            }
            
            if lastX > (layoutWidth - viewWidth) {
                lastY += maxHeight + self.spacing.y
                maxHeight = viewHeight
                lastX = 0
            }
            
            block(NSRect(x: lastX, y: lastY, width: viewWidth, height: viewHeight))
            
            lastX += viewWidth + self.spacing.x
        }
    }
    
}
