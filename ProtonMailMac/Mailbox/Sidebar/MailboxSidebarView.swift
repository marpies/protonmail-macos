//
//  MailboxSidebarView.swift
//  ProtonMailMac
//
//  Created by Marcel Piešťanský on 27.08.2021.
//  Copyright (c) 2021 marpies. All rights reserved.
//

import AppKit

protocol MailboxSidebarViewDelegate: AnyObject {
    //
}

class MailboxSidebarView: NSView {
    
    private let tableView: NSOutlineView = NSOutlineView()
    private let column: NSTableColumn = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("list"))
    
    private lazy var dataSource: MailboxSidebarDataSource = MailboxSidebarDataSource(tableView: self.tableView)
    
    weak var delegate: MailboxSidebarViewDelegate?
    
    // Use the flipped coordinate system to avoid issues with the outline view expanding.
    override var isFlipped: Bool {
        return true
    }
    
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
    
    func displayData(viewModel: MailboxSidebar.Init.ViewModel) {
        self.dataSource.setData(viewModel: viewModel.groups)
        
        NSScrollView().with { scrollView in
            self.addSubview(scrollView)
            scrollView.drawsBackground = false
            scrollView.wantsLayer = true
            scrollView.layer?.backgroundColor = NSColor.clear.cgColor
            scrollView.contentView.wantsLayer = true
            scrollView.contentView.layer?.backgroundColor = NSColor.clear.cgColor
            scrollView.snp.makeConstraints { make in
                make.left.right.equalToSuperview()
                make.top.equalTo(self.safeArea.top)
                make.bottom.equalToSuperview()
            }
            
            self.tableView.with { table in
                table.wantsLayer = true
                table.layer?.backgroundColor = NSColor.clear.cgColor
                table.selectionHighlightStyle = .sourceList
                table.dataSource = self.dataSource
                table.delegate = self.dataSource
                table.focusRingType = .none
                table.addTableColumn(self.column)
                table.rowSizeStyle = .default
                table.headerView = nil
                scrollView.documentView = table
            }
        }
        
        self.dataSource.expandAllItems()
        self.tableView.reloadData()
        
        self.tableView.selectRowIndexes(IndexSet(integer: viewModel.selectedRow), byExtendingSelection: false)
    }
    
    func displayGroupsRefresh(viewModel: MailboxSidebar.RefreshGroups.ViewModel) {
        self.dataSource.setData(viewModel: viewModel.groups)
        
        self.tableView.reloadData()
        self.dataSource.expandAllItems()
        
        self.tableView.selectRowIndexes(IndexSet(integer: viewModel.selectedRow), byExtendingSelection: false)
    }
    
    //
    // MARK: - Private
    //
    
    private func setupView() {
        
    }

}
