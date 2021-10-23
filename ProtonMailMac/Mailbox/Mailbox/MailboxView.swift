//
//  MailboxView.swift
//  ProtonMailMac
//
//  Created by Marcel Piešťanský on 16.09.2021.
//  Copyright (c) 2021 marpies. All rights reserved.
//

import AppKit

protocol MailboxViewDelegate: MailboxDataSourceDelegate, BoxErrorViewDelegate {
    
}

class MailboxView: NSView {
    
    private let scrollView: NSScrollView = NSScrollView()
    private let tableView: NSTableView = NSTableView()
    private let column: NSTableColumn = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("list"))
    
    private lazy var dataSource: MailboxDataSource = MailboxDataSource(tableView: self.tableView)
    
    private var errorView: BoxErrorView?
    
    weak var delegate: MailboxViewDelegate?
    
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
    
    func displayItems(viewModel: Mailbox.LoadItems.ViewModel) {
        if viewModel.removeErrorView {
            self.removeErrorView()
        }
        
        self.dataSource.delegate = self.delegate
        self.dataSource.setData(viewModel: viewModel.items)
        self.tableView.reloadData()
    }
    
    func displayItemsUpdate(viewModel: Mailbox.UpdateItems.ViewModel) {
        self.removeErrorView()
        
        self.dataSource.setData(viewModel: viewModel.items)
        
        guard viewModel.insertSet != nil || viewModel.removeSet != nil || viewModel.updateSet != nil else { return }
        
        self.tableView.beginUpdates()
        
        if let set = viewModel.removeSet {
            self.tableView.removeRows(at: set, withAnimation: .effectFade)
        }
        
        if let set = viewModel.insertSet {
            self.tableView.insertRows(at: set, withAnimation: .effectFade)
        }
        
        if let set = viewModel.updateSet {
            self.tableView.reloadData(forRowIndexes: set, columnIndexes: IndexSet(integer: 0))
        }
        
        self.tableView.endUpdates()
        
        // Update rows height if there is an update set (must be done after calling `endUpdates`)
        if let set = viewModel.updateSet {
            self.tableView.noteHeightOfRows(withIndexesChanged: set)
        }
    }
    
    func displayItemUpdate(viewModel: Mailbox.UpdateItem.ViewModel) {
        let indexSet: IndexSet = IndexSet(integer: viewModel.index)
        
        self.dataSource.updateData(viewModel: viewModel.item, at: viewModel.index)
        self.tableView.reloadData(forRowIndexes: indexSet, columnIndexes: IndexSet(integer: 0))
        self.tableView.noteHeightOfRows(withIndexesChanged: indexSet)
    }
    
    func displayItemsRefresh(viewModel: Mailbox.RefreshItems.ViewModel) {
        for pair in viewModel.items {
            self.dataSource.updateData(viewModel: pair.item, at: pair.index)
        }
        self.tableView.reloadData(forRowIndexes: viewModel.indexSet, columnIndexes: IndexSet(integer: 0))
        self.tableView.noteHeightOfRows(withIndexesChanged: viewModel.indexSet)
    }
    
    func displayMailboxError(viewModel: Mailbox.LoadError.ViewModel) {
        if self.errorView == nil {
            self.errorView = BoxErrorView()
            self.errorView?.delegate = self.delegate
            self.errorView?.with { view in
                self.addSubview(view)
                view.snp.makeConstraints { make in
                    make.left.right.equalToSuperview().inset(8)
                    make.height.greaterThanOrEqualTo(80)
                    make.top.equalTo(self.safeArea.top)
                }
                
                self.scrollView.snp.makeConstraints { make in
                    make.top.equalTo(view.snp.bottom).priority(.required)
                }
            }
        }
        
        self.errorView?.update(message: viewModel.message, button: viewModel.button)
    }
    
    func removeErrorView() {
        self.errorView?.removeFromSuperview()
        self.errorView = nil
    }
    
    //
    // MARK: - Private
    //
    
    private func setupView() {
        self.scrollView.with { scrollView in
            self.addSubview(scrollView)
            scrollView.snp.makeConstraints { make in
                make.left.right.equalToSuperview()
                make.top.equalToSuperview().priority(.high)
                make.bottom.equalToSuperview()
            }
            
            self.tableView.with { table in
                table.gridColor = .separatorColor
                table.gridStyleMask = .solidHorizontalGridLineMask
                table.backgroundColor = .clear
                table.dataSource = self.dataSource
                table.delegate = self.dataSource
                table.focusRingType = .none
                table.allowsMultipleSelection = true
                table.addTableColumn(self.column)
                table.headerView = nil
                table.intercellSpacing = NSSize(width: 0, height: 5)
                scrollView.documentView = table
            }
        }
    }

}
