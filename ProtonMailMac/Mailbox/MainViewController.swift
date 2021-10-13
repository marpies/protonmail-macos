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
}

class MainViewController: NSSplitViewController, MainDisplayLogic, ToolbarUtilizing, MailboxSidebarViewControllerDelegate, MailboxViewControllerDelegate {
	
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
    }
    
}
