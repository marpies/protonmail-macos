//
//  MessagesView.swift
//  ProtonMailMac
//
//  Created by Marcel Piešťanský on 05.09.2021.
//  Copyright (c) 2021 marpies. All rights reserved.
//

import AppKit
import SnapKit

protocol MessagesViewDelegate: MessagesErrorViewDelegate, MessagesDataSourceDelegate {
    func refreshMessagesButtonDidTap()
}

class MessagesView: NSView {
    
    private let scrollView: NSScrollView = NSScrollView()
    private let tableView: NSTableView = NSTableView()
    private let column: NSTableColumn = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("list"))
    
    private lazy var dataSource: MessagesDataSource = MessagesDataSource(tableView: self.tableView)
    
    private var errorView: MessagesErrorView?
    
    weak var delegate: MessagesViewDelegate?
    
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
    
    func displayMessages(viewModel: Messages.LoadMessages.ViewModel) {
        if viewModel.removeErrorView {
            self.removeErrorView()
        }
        
        self.dataSource.delegate = self.delegate
        self.dataSource.setData(viewModel: viewModel.messages)
        self.tableView.reloadData()
    }
    
    func displayMessagesUpdate(viewModel: Messages.UpdateMessages.ViewModel) {
        self.removeErrorView()
        
        self.dataSource.setData(viewModel: viewModel.messages)
        
        guard viewModel.insertSet != nil || viewModel.removeSet != nil || viewModel.updateSet != nil else { return }
        
        self.tableView.beginUpdates()
        
        if let set = viewModel.removeSet {
            self.tableView.removeRows(at: set, withAnimation: .effectFade)
        }
        
        if let set = viewModel.insertSet {
            self.tableView.insertRows(at: set, withAnimation: .effectFade)
        }
        
        if let set = viewModel.updateSet {
            self.tableView.noteHeightOfRows(withIndexesChanged: set)
            self.tableView.reloadData(forRowIndexes: set, columnIndexes: IndexSet(integer: 0))
        }

        self.tableView.endUpdates()
    }
    
    func displayMessageUpdate(viewModel: Messages.UpdateMessage.ViewModel) {
        self.dataSource.updateData(viewModel: viewModel.message, at: viewModel.index)
        self.tableView.reloadData(forRowIndexes: IndexSet(integer: viewModel.index), columnIndexes: IndexSet(integer: 0))
    }
    
    func displayMessagesError(viewModel: Messages.LoadError.ViewModel) {
        if self.errorView == nil {
            self.errorView = MessagesErrorView()
            self.errorView?.delegate = self.delegate
            self.errorView?.with { view in
                view.wantsLayer = true
                view.layer?.backgroundColor = NSColor.red.cgColor
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
        
        self.errorView?.update(viewModel: viewModel)
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
            scrollView.drawsBackground = false
            scrollView.snp.makeConstraints { make in
                make.left.right.equalToSuperview()
                make.top.equalTo(self.safeArea.top).priority(.high)
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
