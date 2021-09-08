//
//  MailboxSidebarDataSource.swift
//  ProtonMailMac
//
//  Created by Marcel Piešťanský on 27.08.2021.
//  Copyright © 2021 marpies. All rights reserved.
//

import Foundation
import AppKit

protocol MailboxSidebarDataSourceDelegate: AnyObject {
    func mailboxSidebarDidSelectItem(_ item: MailboxSidebar.Item.ViewModel)
}

class MailboxSidebarDataSource: NSObject, NSOutlineViewDelegate, NSOutlineViewDataSource {
    
    private typealias Group = MailboxSidebar.Group.ViewModel
    private typealias Item = MailboxSidebar.Item.ViewModel
    
    private let tableView: NSOutlineView
    
    private var viewModel: [Group] = []
    
    weak var delegate: MailboxSidebarDataSourceDelegate?
    
    init(tableView: NSOutlineView) {
        self.tableView = tableView
    }
    
    //
    // MARK: - Public
    //
    
    func setData(viewModel: [MailboxSidebar.Group.ViewModel]) {
        self.viewModel.removeAll()
        self.viewModel.append(contentsOf: viewModel)
    }
    
    func expandAllItems() {
        for group in self.viewModel {
            self.tableView.expandItem(group)
        }
    }
    
    //
    // MARK: - Outline view delegate / data source
    //
    
    func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        if let group = item as? Group {
            return group.labels.count
        }
        if let item = item as? Item {
            return item.children?.count ?? 0
        }
        return self.viewModel.count
    }
    
    func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
        if item is Group {
            return true
        }
        if let item = item as? Item, let children = item.children, !children.isEmpty {
            return true
        }
        return false
    }
    
    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        if let group = item as? Group {
            return group.labels[index]
        }
        if let item = item as? Item, let children = item.children {
            return children[index]
        }
        return self.viewModel[index]
    }
    
    func outlineView(_ outlineView: NSOutlineView, objectValueFor tableColumn: NSTableColumn?, byItem item: Any?) -> Any? {
        if let group = item as? Group {
            return group.title
        }
        if let item = item as? Item {
            return item.title
        }
        return nil
    }
    
    func outlineView(_ outlineView: NSOutlineView, isGroupItem item: Any) -> Bool {
        return item is Group
    }
    
    func outlineView(_ outlineView: NSOutlineView, shouldSelectItem item: Any) -> Bool {
        if item is Group {
            return false
        }
        return true
    }
    
    func outlineView(_ outlineView: NSOutlineView, rowViewForItem item: Any) -> NSTableRowView? {
        // Use non-emphasized rows to avoid tinted selection
        return MailboxSidebarRowView()
    }
    
    func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
        if let group = item as? Group {
            let defaultLabel: NSTextField? = outlineView.makeView(withIdentifier: NSUserInterfaceItemIdentifier("title"), owner: self) as? NSTextField
            let label: NSTextField = defaultLabel ?? NSTextField.asLabel
            label.stringValue = group.title
            
            // Default font for macOS 10.15 and lower
            if #available(macOS 11.0, *) { } else {
                label.setPreferredFont(style: .subheadline)
            }
            
            return label
        }
        
        if let item = item as? Item {
            let cell: NSTableCellView
            
            if let existingCell = outlineView.makeView(withIdentifier: NSUserInterfaceItemIdentifier("item"), owner: self) as? NSTableCellView {
                cell = existingCell
            } else {
                cell = NSTableCellView()
                let imageView: NSImageView = NSImageView()
                imageView.setContentHuggingPriority(.defaultHigh, for: .horizontal)
                cell.addSubview(imageView)
                cell.imageView = imageView
                imageView.snp.makeConstraints { make in
                    make.left.equalToSuperview()
                    make.width.greaterThanOrEqualTo(20)
                    make.centerY.equalToSuperview()
                }
                
                let label = NSTextField.asLabel
                label.stringValue = item.title
                label.setContentHuggingPriority(.defaultLow, for: .horizontal)
                
                // Default font for macOS 10.15 and lower
                if #available(macOS 11.0, *) { } else {
                    label.setPreferredFont(style: .body)
                }
                
                cell.addSubview(label)
                cell.textField = label
                label.snp.makeConstraints { make in
                    make.left.equalTo(imageView.snp.right).offset(8)
                    make.centerY.equalToSuperview()
                    make.right.equalToSuperview()
                }
            }
            
            cell.textField?.stringValue = item.title
            
            if #available(macOS 11.0, *) {
                cell.imageView?.image = NSImage(systemSymbolName: item.icon, accessibilityDescription: item.icon)
            } else {
                // todo fallback icon
            }
            
            return cell
        }
        
        return nil
    }
    
    @available(macOS 11.0, *)
    func outlineView(_ outlineView: NSOutlineView, tintConfigurationForItem item: Any) -> NSTintConfiguration? {
        if let item = item as? Item {
            if let color = item.color {
                return NSTintConfiguration(fixedColor: color)
            }
            return NSTintConfiguration.monochrome
        }
        return nil
    }
    
    func outlineViewSelectionDidChange(_ notification: Notification) {
        guard let view = notification.object as? NSOutlineView else { return }
        
        if let item = view.item(atRow: view.selectedRow) as? Item {
            self.delegate?.mailboxSidebarDidSelectItem(item)
        }
    }
    
}
