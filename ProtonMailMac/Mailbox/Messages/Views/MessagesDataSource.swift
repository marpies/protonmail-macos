//
//  MessagesDataSource.swift
//  ProtonMailMac
//
//  Created by Marcel Piešťanský on 08.09.2021.
//  Copyright © 2021 marpies. All rights reserved.
//

import Foundation
import AppKit

protocol MessagesDataSourceDelegate: MessageTableCellViewDelegate {
    func messagesDidSelect(ids: [String])
}

class MessagesDataSource: NSObject, NSTableViewDelegate, NSTableViewDataSource {
    
    private let cellId = NSUserInterfaceItemIdentifier("message")
    private let tableView: NSTableView
    
    private var viewModel: [Messages.Message.ViewModel] = []
    
    weak var delegate: MessagesDataSourceDelegate?

    init(tableView: NSTableView) {
        self.tableView = tableView
    }
    
    //
    // MARK: - Public
    //
    
    func setData(viewModel: [Messages.Message.ViewModel]) {
        self.viewModel.removeAll()
        self.viewModel.append(contentsOf: viewModel)
    }
    
    func updateData(viewModel: Messages.Message.ViewModel, at index: Int) {
        self.viewModel[index] = viewModel
    }
    
    //
    // MARK: - Table view delegate / data source
    //
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return self.viewModel.count
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let cell: MessageTableCellView
        
        if let existingCell = tableView.makeView(withIdentifier: self.cellId, owner: self) as? MessageTableCellView {
            cell = existingCell
        } else {
            cell = MessageTableCellView()
            cell.identifier = self.cellId
        }
        
        let message = self.viewModel[row]
        
        cell.delegate = self.delegate
        cell.update(viewModel: message)
        
        return cell
    }
    
    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        let message: Messages.Message.ViewModel = self.viewModel[row]
        if message.labels != nil {
            return 90
        }
        return 70
    }
    
    func tableViewSelectionDidChange(_ notification: Notification) {
        let ids: [String] = self.tableView.selectedRowIndexes.map { self.viewModel[$0].id }
        
        self.delegate?.messagesDidSelect(ids: ids)
    }
    
}
