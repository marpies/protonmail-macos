//
//  MailboxViewController.swift
//  ProtonMailMac
//
//  Created by Marcel Piešťanský on 25.08.2021.
//  Copyright (c) 2021 marpies. All rights reserved.
//

import AppKit

protocol MailboxDisplayLogic: AnyObject {
	func displayData(viewModel: Mailbox.Init.ViewModel)
}

class MailboxViewController: NSSplitViewController, MailboxDisplayLogic, ToolbarUtilizing, MailboxSidebarViewControllerDelegate {
	
	var interactor: MailboxBusinessLogic?
	var router: (MailboxRoutingLogic & MailboxDataPassing)?
    var sidebarViewController: MailboxSidebarViewController?
    var conversationsViewController: ConversationsViewController?
    var messageDetailsViewController: MessageDetailsViewController?
    
    weak var toolbarDelegate: ToolbarUtilizingDelegate?
    
    private var overlayView: MailboxOverlayView?
	
	//	
	// MARK: - View lifecycle
	//
    
    override func loadView() {
        self.sidebarViewController?.delegate = self
        self.sidebarViewController?.view.widthAnchor.constraint(greaterThanOrEqualToConstant: 180).isActive = true
        self.conversationsViewController?.view.widthAnchor.constraint(greaterThanOrEqualToConstant: 360).isActive = true
        self.messageDetailsViewController?.view.widthAnchor.constraint(greaterThanOrEqualToConstant: 600).isActive = true
        
        let sidebarItem = NSSplitViewItem(sidebarWithViewController: self.sidebarViewController!)
        sidebarItem.canCollapse = false
        addSplitViewItem(sidebarItem)
        
        let contentItem = NSSplitViewItem(contentListWithViewController: self.conversationsViewController!)
        addSplitViewItem(contentItem)
        
        let detailsItem = NSSplitViewItem(viewController: self.messageDetailsViewController!)
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
		let request = Mailbox.Init.Request()
		self.interactor?.loadData(request: request)
	}
	
	func displayData(viewModel: Mailbox.Init.ViewModel) {
        self.overlayView = MailboxOverlayView().with { view in
            view.update(message: viewModel.loadingMessage)
            self.view.addSubview(view)
            view.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
        }
        
        // todo wait for sections to initialize
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.removeOverlay()
        }
	}
    
    //
    // MARK: - Sidebar delegate
    //
    
    func mailboxSidebarDidSelectLabel(id: String) {
        self.conversationsViewController?.loadConversations(labelId: id)
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
