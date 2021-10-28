//
//  MainToolbarDataSource.swift
//  ProtonMailMac
//
//  Created by Marcel Piešťanský on 21.10.2021.
//  Copyright © 2021 marpies. All rights reserved.
//

import Foundation
import AppKit

protocol MainToolbarDataSourceDelegate: NSToolbarSegmentedControlDelegate {
    func toolbarItemDidTap(id: NSToolbarItem.Identifier)
    func toolbarMenuItemDidTap(id: String, state: NSControl.StateValue)
}

class MainToolbarDataSource {
    
    private let splitView: NSSplitView
    
    weak var delegate: MainToolbarDataSourceDelegate?
    
    init(splitView: NSSplitView) {
        self.splitView = splitView
    }
    
    //
    // MARK: - Public
    //
    
    func getToolbarItem(viewModel: Main.ToolbarItem.ViewModel) -> NSToolbarItem? {
        switch viewModel {
        case .trackingItem(let id, let index):
            if #available(macOS 11.0, *) {
                return NSTrackingSeparatorToolbarItem(identifier: id, splitView: self.splitView, dividerIndex: index)
            }
            return nil
            
        case .button(let id, let label, let tooltip, let icon, let isEnabled):
            let toolbarItem: NSToolbarItem = NSToolbarItem(itemIdentifier: id)
            
            toolbarItem.label = label
            toolbarItem.paletteLabel = label
            toolbarItem.toolTip = tooltip
            toolbarItem.isEnabled = isEnabled
            
            if isEnabled {
                toolbarItem.action = #selector(self.toolbarItemDidTap)
                toolbarItem.target = self
            }
            
            if #available(macOS 10.15, *) {
                toolbarItem.isBordered = true
            }
            
            if #available(macOS 11.0, *) {
                toolbarItem.image = NSImage(systemSymbolName: icon, accessibilityDescription: nil)
            } else {
                // todo fallback image
            }
            
            let menuItem: NSMenuItem = NSMenuItem()
            menuItem.submenu = nil
            menuItem.title = label
            toolbarItem.menuFormRepresentation = menuItem
            
            return toolbarItem
            
        case .group(let id, let items):
            let group: NSToolbarItemGroup = NSToolbarItemGroup(itemIdentifier: id)
            
            group.subitems = items.compactMap { self.getToolbarItem(viewModel: $0) }
            
            let segmented: NSToolbarSegmentedControl = NSToolbarSegmentedControl()
            segmented.segmentStyle = .texturedRounded
            segmented.trackingMode = .momentary
            segmented.segmentCount = items.count
            segmented.items = group.subitems.map { $0.itemIdentifier }
            segmented.delegate = self.delegate
            
            for (index, item) in group.subitems.enumerated() {
                segmented.setImage(item.image, forSegment: index)
                segmented.setWidth(40, forSegment: index)
                segmented.setEnabled(item.isEnabled, forSegment: index)
                segmented.setToolTip(item.toolTip, forSegment: index)
            }
            
            group.view = segmented
            
            return group
            
        case .buttonMenu(let id, let title, let label, let tooltip, let icon, let isEnabled, let items):
            let toolbarItem: NSToolbarItem = NSToolbarItem(itemIdentifier: id)
            toolbarItem.label = label
            toolbarItem.toolTip = tooltip
            toolbarItem.isEnabled = isEnabled
            
            toolbarItem.view = NSMenuButton().with { button in
                if #available(macOS 11.0, *) {
                    button.image = NSImage(systemSymbolName: icon, accessibilityDescription: nil)
                } else {
                    // todo fallback image
                }
                
                button.setButtonType(.momentaryLight)
                button.isEnabled = isEnabled
                button.bezelStyle = .texturedRounded
                button.title = title
                button.imagePosition = .imageLeft
                button.alignment = .left
                
                button.menu = NSMenu().with { menu in
                    let menuItems: [NSMenuItem] = items.map { self.getMenuItem(viewModel: $0) }

                    menu.autoenablesItems = false
                    menu.items = menuItems
                }
            }
            
            toolbarItem.view?.snp.makeConstraints { make in
                make.width.greaterThanOrEqualTo(140)
            }
            
            return toolbarItem
            
        case .imageMenu(let id, let label, let tooltip, let icon, let isEnabled, let items):
            let toolbarItem: NSMenuToolbarItem = NSMenuToolbarItem(itemIdentifier: id)
            toolbarItem.label = label
            toolbarItem.toolTip = tooltip
            toolbarItem.isEnabled = isEnabled
            toolbarItem.showsIndicator = true
            
            if #available(macOS 11.0, *) {
                toolbarItem.image = NSImage(systemSymbolName: icon, accessibilityDescription: nil)
            } else {
                // todo fallback image
            }
            
            toolbarItem.menu = NSMenu().with { menu in
                let menuItems: [NSMenuItem] = items.map { self.getMenuItem(viewModel: $0) }
                
                menu.autoenablesItems = false
                menu.items = menuItems
            }
            
            return toolbarItem
            
        case .spacer:
            return nil
        }
    }
    
    //
    // MARK: - Private
    //
    
    private func getMenuItem(viewModel: Main.ToolbarItem.MenuItem.ViewModel) -> NSMenuItem {
        let menuItem: IdentifiedNSMenuItem = IdentifiedNSMenuItem()
        menuItem.title = viewModel.title
        menuItem.itemIdRaw = viewModel.id
        
        if let icon = viewModel.icon {
            if #available(macOS 11.0, *) {
                menuItem.image = NSImage(systemSymbolName: icon, accessibilityDescription: nil)?.tinted(color: viewModel.color)
            } else {
                // todo fallback icon
            }
        }
        
        menuItem.isEnabled = viewModel.isEnabled
        menuItem.target = self
        menuItem.action = #selector(self.toolbarMenuItemDidTap)
        
        if let state = viewModel.state {
            menuItem.state = state
        }
        
        if let children = viewModel.children {
            menuItem.submenu = NSMenu().with { menu in
                let menuItems: [NSMenuItem] = children.map { self.getMenuItem(viewModel: $0) }
                
                menu.items = menuItems
            }
        }
        
        return menuItem
    }
    
    //
    // MARK: - Toolbar event handlers
    //
    
    @objc private func toolbarItemDidTap(_ sender: NSToolbarItem) {
        self.delegate?.toolbarItemDidTap(id: sender.itemIdentifier)
    }
    
    @objc private func toolbarMenuItemDidTap(_ sender: Any) {
        if let item = sender as? IdentifiedNSMenuItem, let id = item.itemIdRaw {
            self.delegate?.toolbarMenuItemDidTap(id: id, state: item.state)
        }
    }
    
}
