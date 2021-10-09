//
//  ToolbarUtilizing.swift
//  ProtonMailMac
//
//  Created by Marcel Piešťanský on 25.08.2021.
//  Copyright © 2021 marpies. All rights reserved.
//

import Foundation
import AppKit

protocol ToolbarUtilizingDelegate: AnyObject {
    func toolbarTitleDidUpdate(title: String, subtitle: String?)
    func toolbarItemsDidUpdate(identifiers: [NSToolbarItem.Identifier], items: [NSToolbarItem])
}

protocol ToolbarUtilizing: AnyObject {
    var toolbarDelegate: ToolbarUtilizingDelegate? { get set }
}
