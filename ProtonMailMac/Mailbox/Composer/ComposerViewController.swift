//
//  ComposerViewController.swift
//  ProtonMailMac
//
//  Created by Marcel Piešťanský on 26.11.2021.
//  Copyright (c) 2021 marpies. All rights reserved.
//

import AppKit

protocol ComposerDisplayLogic: AnyObject {
	func displayInitialData(viewModel: Composer.Init.ViewModel)
    func displayToolbarUpdate(viewModel: Composer.UpdateToolbar.ViewModel)
}

class ComposerViewController: NSViewController, ComposerDisplayLogic, ComposerViewDelegate, NSWindowDelegate, MainToolbarDataSourceDelegate {
    
    private let mainView: ComposerView = ComposerView()
    
    private var toolbarDataSource: MainToolbarDataSource?
	
	var interactor: ComposerBusinessLogic?
	var router: (ComposerRoutingLogic & ComposerDataPassing)?
    
    weak var toolbarDelegate: ToolbarUtilizingDelegate?
	
	//	
	// MARK: - View lifecycle
	//
    
    override func loadView() {
        self.mainView.delegate = self
        self.view = self.mainView
        self.view.frame = CGRect(x: 0, y: 0, width: NSSize.defaultWindow.width / 2, height: NSSize.defaultWindow.height * 0.8)
        
        self.toolbarDataSource = MainToolbarDataSource()
        self.toolbarDataSource?.delegate = self
    }
	
	override func viewDidLoad() {
		super.viewDidLoad()

		self.loadData()
	}
	
	//	
	// MARK: - Load data
	//
	
	private func loadData() {
		let request = Composer.Init.Request()
		self.interactor?.loadData(request: request)
	}
	
	func displayInitialData(viewModel: Composer.Init.ViewModel) {
        self.mainView.displayInitialData(viewModel: viewModel)
	}
    
    //
    // MARK: - Display toolbar update
    //
    
    func displayToolbarUpdate(viewModel: Composer.UpdateToolbar.ViewModel) {
        let items: [NSToolbarItem] = viewModel.items.compactMap { self.toolbarDataSource?.getToolbarItem(viewModel: $0) }
        self.toolbarDelegate?.toolbarItemsDidUpdate(identifiers: viewModel.identifiers, items: items)
    }
    
    //
    // MARK: - Window delegate
    //
    
    func windowShouldClose(_ sender: NSWindow) -> Bool {
        // todo ask to save draft or not
        return true
    }
    
    //
    // MARK: - Toolbar segmented control delegate
    //
    
    func toolbarGroupSegmentDidClick(id: NSToolbarItem.Identifier) {
    }
    
    //
    // MARK: - Toolbar data source
    //
    
    func toolbarItemDidTap(id: NSToolbarItem.Identifier) {
    }
    
    func toolbarMenuItemDidTap(id: MenuItemIdentifier, state: NSControl.StateValue) {
    }
    
}
