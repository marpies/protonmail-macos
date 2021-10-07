//
//  MailboxSidebarItemCellView.swift
//  ProtonMailMac
//
//  Created by Marcel Piešťanský on 07.10.2021.
//  Copyright © 2021 marpies. All rights reserved.
//

import Foundation
import AppKit
import SnapKit

class MailboxSidebarItemCellView: NSTableCellView {
    
    private var badgeView: UnreadBadgeView?
    
    func update(viewModel: MailboxSidebar.Item.ViewModel) {
        // Icon
        self.updateIcon(viewModel.icon)
        
        // Label
        self.updateTitleLabel(viewModel.title)
        
        // Optional badge
        if let badge = viewModel.badge {
            self.addBadgeView(badge)
        } else {
            self.removeBadgeView()
        }
    }
    
    //
    // MARK: - Private
    //
    
    private func updateIcon(_ icon: String) {
        if #available(macOS 11.0, *) {
            if self.imageView == nil {
                let imageView: NSImageView = NSImageView()
                imageView.setContentHuggingPriority(.defaultHigh, for: .horizontal)
                self.addSubview(imageView)
                self.imageView = imageView
                imageView.snp.makeConstraints { make in
                    make.left.equalToSuperview()
                    make.width.greaterThanOrEqualTo(20)
                    make.centerY.equalToSuperview()
                }
            }
            
            self.imageView?.image = NSImage(systemSymbolName: icon, accessibilityDescription: icon)
        } else {
            // todo fallback icon
        }
    }
    
    private func updateTitleLabel(_ title: String) {
        if self.textField == nil {
            let label: NSTextField = NSTextField.asLabel
            label.setContentHuggingPriority(.defaultLow, for: .horizontal)
            
            // Default font for macOS 10.15 and lower
            if #available(macOS 11.0, *) { } else {
                label.setPreferredFont(style: .body)
            }
            
            self.addSubview(label)
            self.textField = label
            
            label.snp.makeConstraints { make in
                if #available(macOS 11.0, *) {
                    make.left.equalTo(self.imageView!.snp.right).offset(8)
                } else {
                    // todo font icon label
                }
                make.centerY.equalToSuperview()
            }
        }
        
        self.textField?.stringValue = title
    }
    
    private func addBadgeView(_ badge: String) {
        if self.badgeView == nil {
            self.badgeView = UnreadBadgeView().with { view in
                view.setContentHuggingPriority(.defaultHigh, for: .horizontal)
                view.setContentCompressionResistancePriority(.required, for: .horizontal)
                self.addSubview(view)
                view.snp.makeConstraints { make in
                    make.right.equalToSuperview()
                    make.centerY.equalToSuperview()
                    make.left.equalTo(self.textField!.snp.right)
                    make.width.greaterThanOrEqualTo(view.snp.height)
                }
            }
        }
        
        self.badgeView?.update(title: badge)
    }
    
    private func removeBadgeView() {
        guard let view = self.badgeView else { return }
        
        self.badgeView = nil
        view.removeFromSuperview()
    }
    
}
