//
//  ConversationsView.swift
//  ProtonMailMac
//
//  Created by Marcel Piešťanský on 16.09.2021.
//  Copyright (c) 2021 marpies. All rights reserved.
//

import AppKit

protocol ConversationsViewDelegate: ConversationsDataSourceDelegate, BoxErrorViewDelegate {
    func refreshMessagesButtonDidTap()
}

class ConversationsView: NSView {
    
    private let scrollView: NSScrollView = NSScrollView()
    private let tableView: NSTableView = NSTableView()
    private let column: NSTableColumn = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("list"))
    
    private lazy var dataSource: ConversationsDataSource = ConversationsDataSource(tableView: self.tableView)
    
    private var errorView: BoxErrorView?
    
    weak var delegate: ConversationsViewDelegate?
    
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
    
    func displayConversations(viewModel: Conversations.LoadConversations.ViewModel) {
        if viewModel.removeErrorView {
            self.removeErrorView()
        }
        
        self.dataSource.delegate = self.delegate
        self.dataSource.setData(viewModel: viewModel.conversations)
        self.tableView.reloadData()
    }
    
    func displayConversationsUpdate(viewModel: Conversations.UpdateConversations.ViewModel) {
        self.removeErrorView()
        
        self.dataSource.setData(viewModel: viewModel.conversations)
        
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
    
    func displayConversationUpdate(viewModel: Conversations.UpdateConversation.ViewModel) {
        self.dataSource.updateData(viewModel: viewModel.conversation, at: viewModel.index)
        self.tableView.reloadData(forRowIndexes: IndexSet(integer: viewModel.index), columnIndexes: IndexSet(integer: 0))
    }
    
    func displayConversationsError(viewModel: Conversations.LoadError.ViewModel) {
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
        
        NSButton().with { button in
            button.bezelStyle = .rounded
            button.title = "Reload"
            button.controlSize = .small
            button.target = self
            button.action = #selector(self.buttonDidTap)
            self.addSubview(button)
            button.snp.makeConstraints { make in
                make.centerX.equalToSuperview()
                make.top.equalTo(self.safeArea.top)
            }
        }
    }
    
    @objc private func buttonDidTap() {
        self.delegate?.refreshMessagesButtonDidTap()
    }

}
