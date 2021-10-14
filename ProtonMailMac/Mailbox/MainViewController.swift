//
//  MainViewController.swift
//  ProtonMailMac
//
//  Created by Marcel Piešťanský on 25.08.2021.
//  Copyright (c) 2021 marpies. All rights reserved.
//

import AppKit

protocol MainDisplayLogic: AnyObject {
	func displayData(viewModel: Main.Init.ViewModel)
    func displayTitle(viewModel: Main.LoadTitle.ViewModel)
    func displayToolbarUpdate(viewModel: Main.UpdateToolbar.ViewModel)
}

class MainViewController: NSSplitViewController, MainDisplayLogic, ToolbarUtilizing, MailboxSidebarViewControllerDelegate, MailboxViewControllerDelegate, NSToolbarSegmentedControlDelegate {
	
	var interactor: MainBusinessLogic?
	var router: (MainRoutingLogic & MainDataPassing)?
    var sidebarViewController: MailboxSidebarViewController?
    var mailboxViewController: MailboxViewController?
    var conversationDetailsViewController: ConversationDetailsViewController?
    
    weak var toolbarDelegate: ToolbarUtilizingDelegate?
    
    private var overlayView: MailboxOverlayView?
    
    /// Dispatch group tracking individual sections initialization.
    /// We show the content only once the sections are initialized.
    private var sceneInitGroup: DispatchGroup? = DispatchGroup()
	
	//	
	// MARK: - View lifecycle
	//
    
    override func loadView() {
        self.sidebarViewController?.delegate = self
        self.sidebarViewController?.view.widthAnchor.constraint(greaterThanOrEqualToConstant: 180).isActive = true
        self.mailboxViewController?.delegate = self
        self.mailboxViewController?.view.widthAnchor.constraint(greaterThanOrEqualToConstant: 360).isActive = true
        self.conversationDetailsViewController?.view.widthAnchor.constraint(greaterThanOrEqualToConstant: 600).isActive = true
        
        self.sceneInitGroup?.enter()
        self.sceneInitGroup?.enter()
        
        self.sceneInitGroup?.notify(queue: .main) { [weak self] in
            self?.sceneInitGroup = nil
            self?.removeOverlay()
        }
        
        let sidebarItem = NSSplitViewItem(sidebarWithViewController: self.sidebarViewController!)
        sidebarItem.canCollapse = false
        addSplitViewItem(sidebarItem)
        
        let contentItem = NSSplitViewItem(contentListWithViewController: self.mailboxViewController!)
        addSplitViewItem(contentItem)
        
        let detailsItem = NSSplitViewItem(viewController: self.conversationDetailsViewController!)
        addSplitViewItem(detailsItem)
        
        super.loadView()
    }
	
	override func viewDidLoad() {
		super.viewDidLoad()

		self.loadData()
	}
	
	//	
	// MARK: - Load data
	//
	
	private func loadData() {
		let request = Main.Init.Request()
		self.interactor?.loadData(request: request)
	}
	
	func displayData(viewModel: Main.Init.ViewModel) {
        self.overlayView = MailboxOverlayView().with { view in
            view.update(message: viewModel.loadingMessage)
            self.view.addSubview(view)
            view.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
        }
	}
    
    //
    // MARK: - Display title
    //
    
    func displayTitle(viewModel: Main.LoadTitle.ViewModel) {
        self.toolbarDelegate?.toolbarTitleDidUpdate(title: viewModel.title, subtitle: viewModel.subtitle)
    }
    
    //
    // MARK: - Display toolbar update
    //
    
    func displayToolbarUpdate(viewModel: Main.UpdateToolbar.ViewModel) {
        let items: [NSToolbarItem] = viewModel.items.compactMap { self.getToolbarItem(viewModel: $0) }
        self.toolbarDelegate?.toolbarItemsDidUpdate(identifiers: viewModel.identifiers, items: items)
    }
    
    //
    // MARK: - Sidebar delegate
    //
    
    func mailboxSidebarDidSelectLabel(id: String) {
        self.mailboxViewController?.loadMailbox(labelId: id)
        
        let request = Main.LoadTitle.Request(labelId: id)
        self.interactor?.loadTitle(request: request)
    }
    
    func mailboxSidebarDidInitialize() {
        self.sceneInitGroup?.leave()
    }
    
    //
    // MARK: - Mailbox delegate
    //
    
    func conversationDidRequestLoad(conversationId: String) {
        self.conversationDetailsViewController?.loadConversation(id: conversationId)
    }
    
    func mailboxSceneDidInitialize() {
        self.sceneInitGroup?.leave()
    }
    
    func mailboxSelectionDidUpdate(viewModel: Mailbox.ItemsDidSelect.ViewModel) {
        let request: Main.MailboxSelectionDidUpdate.Request = Main.MailboxSelectionDidUpdate.Request(type: viewModel.type)
        self.interactor?.processMailboxSelectionUpdate(request: request)
    }
    
    //
    // MARK: - Private
    //
    
    private func removeOverlay() {
        guard let view = self.overlayView else { return }
        
        self.overlayView = nil
        
        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.3
            ctx.timingFunction = CAMediaTimingFunction(name: .easeOut)
            view.animator().alphaValue = 0
        } completionHandler: {
            view.removeFromSuperview()
        }
        
        self.interactor?.processSceneDidInitialize()
    }
    
    //
    // MARK: - Toolbar items
    //
    
    private func getToolbarItem(viewModel: Main.ToolbarItem.ViewModel) -> NSToolbarItem? {
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
            segmented.delegate = self
            
            for (index, item) in group.subitems.enumerated() {
                segmented.setImage(item.image, forSegment: index)
                segmented.setWidth(40, forSegment: index)
                segmented.setEnabled(item.isEnabled, forSegment: index)
                segmented.setToolTip(item.toolTip, forSegment: index)
            }
            
            group.view = segmented
            
            return group
            
        case .spacer:
            return nil
        }
    }
    
    @objc private func toolbarItemDidTap(_ sender: NSToolbarItem) {
        let request: Main.ToolbarAction.Request = Main.ToolbarAction.Request(id: sender.itemIdentifier)
        self.interactor?.processToolbarAction(request: request)
    }
    
    //
    // MARK: - Toolbar segmented control delegate
    //
    
    func toolbarGroupSegmentDidClick(id: NSToolbarItem.Identifier) {
        let request: Main.ToolbarAction.Request = Main.ToolbarAction.Request(id: id)
        self.interactor?.processToolbarAction(request: request)
    }
    
}
