//
//  ConversationsDataSource.swift
//  ProtonMailMac
//
//  Created by Marcel Piešťanský on 08.09.2021.
//  Copyright © 2021 marpies. All rights reserved.
//

import Foundation
import AppKit

protocol ConversationsDataSourceDelegate: ConversationTableCellViewDelegate {
    func itemsDidSelect(ids: [String], type: Conversations.TableItem.Kind)
}

class ConversationsDataSource: NSObject, NSTableViewDelegate, NSTableViewDataSource {
    
    private let cellId = NSUserInterfaceItemIdentifier("message")
    private let tableView: NSTableView
    
    private var viewModel: [Conversations.TableItem.ViewModel] = []
    
    weak var delegate: ConversationsDataSourceDelegate?

    init(tableView: NSTableView) {
        self.tableView = tableView
    }
    
    //
    // MARK: - Public
    //
    
    func setData(viewModel: [Conversations.TableItem.ViewModel]) {
        self.viewModel.removeAll()
        self.viewModel.append(contentsOf: viewModel)
    }
    
    func updateData(viewModel: Conversations.TableItem.ViewModel, at index: Int) {
        self.viewModel[index] = viewModel
    }
    
    //
    // MARK: - Table view delegate / data source
    //
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return self.viewModel.count
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let cell: ConversationTableCellView
        
        if let existingCell = tableView.makeView(withIdentifier: self.cellId, owner: self) as? ConversationTableCellView {
            cell = existingCell
        } else {
            cell = ConversationTableCellView()
            cell.identifier = self.cellId
        }
        
        let message = self.viewModel[row]
        
        cell.delegate = self.delegate
        cell.update(viewModel: message)
        
        return cell
    }
    
    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        let message: Conversations.TableItem.ViewModel = self.viewModel[row]
        if message.labels != nil {
            return 90
        }
        return 70
    }
    
    func tableViewSelectionDidChange(_ notification: Notification) {
        guard !self.tableView.selectedRowIndexes.isEmpty else { return }
        
        let type: Conversations.TableItem.Kind = self.viewModel.first?.type ?? .conversation
        let ids: [String] = self.tableView.selectedRowIndexes.map { self.viewModel[$0].id }
        
        self.delegate?.itemsDidSelect(ids: ids, type: type)
    }
    
}
