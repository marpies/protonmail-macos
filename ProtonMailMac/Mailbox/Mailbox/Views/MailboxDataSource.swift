//
//  MailboxDataSource.swift
//  ProtonMailMac
//
//  Created by Marcel Piešťanský on 08.09.2021.
//  Copyright © 2021 marpies. All rights reserved.
//

import Foundation
import AppKit

protocol MailboxDataSourceDelegate: MailboxTableCellViewDelegate {
    func itemsDidSelect(ids: [String], type: Mailbox.TableItem.Kind)
}

class MailboxDataSource: NSObject, NSTableViewDelegate, NSTableViewDataSource {
    
    private let cellId = NSUserInterfaceItemIdentifier("message")
    private let tableView: NSTableView
    
    private var viewModel: [Mailbox.TableItem.ViewModel] = []
    
    weak var delegate: MailboxDataSourceDelegate?

    init(tableView: NSTableView) {
        self.tableView = tableView
    }
    
    //
    // MARK: - Public
    //
    
    func setData(viewModel: [Mailbox.TableItem.ViewModel]) {
        self.viewModel.removeAll()
        self.viewModel.append(contentsOf: viewModel)
    }
    
    func updateData(viewModel: Mailbox.TableItem.ViewModel, at index: Int) {
        self.viewModel[index] = viewModel
    }
    
    //
    // MARK: - Table view delegate / data source
    //
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return self.viewModel.count
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let cell: MailboxTableCellView
        
        if let existingCell = tableView.makeView(withIdentifier: self.cellId, owner: self) as? MailboxTableCellView {
            cell = existingCell
        } else {
            cell = MailboxTableCellView()
            cell.identifier = self.cellId
        }
        
        let message = self.viewModel[row]
        
        cell.delegate = self.delegate
        cell.update(viewModel: message)
        
        return cell
    }
    
    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        let message: Mailbox.TableItem.ViewModel = self.viewModel[row]
        if message.labels != nil {
            return 90
        }
        return 70
    }
    
    func tableViewSelectionDidChange(_ notification: Notification) {
        guard !self.tableView.selectedRowIndexes.isEmpty else { return }
        
        let type: Mailbox.TableItem.Kind = self.viewModel.first?.type ?? .conversation
        let ids: [String] = self.tableView.selectedRowIndexes.map { self.viewModel[$0].id }
        
        self.delegate?.itemsDidSelect(ids: ids, type: type)
    }
    
}