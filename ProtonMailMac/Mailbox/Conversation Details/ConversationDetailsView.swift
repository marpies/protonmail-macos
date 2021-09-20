//
//  ConversationDetailsView.swift
//  ProtonMailMac
//
//  Created by Marcel Piešťanský on 17.09.2021.
//  Copyright (c) 2021 marpies. All rights reserved.
//

import AppKit
import SnapKit

protocol ConversationDetailsViewDelegate: ConversationDetailsHeaderViewDelegate, ConversationsErrorViewDelegate, MessageDetailsViewDelegate {
    //
}

class ConversationDetailsView: NSView {
    
    private let headerView: ConversationDetailsHeaderView = ConversationDetailsHeaderView()
    private let scrollView: NSScrollView = NSScrollView()
    private let contentStackView: FlippedStackView = FlippedStackView()
    
    private let spinnerView: NSProgressIndicator = NSProgressIndicator()
    
    private var errorView: ConversationsErrorView?
    
    weak var delegate: ConversationDetailsViewDelegate? {
        didSet {
            self.headerView.headerDelegate = self.delegate
        }
    }
    
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
    
    func displayConversation(viewModel: ConversationDetails.Load.ViewModel) {
        self.headerView.update(title: viewModel.conversation.title, starIcon: viewModel.conversation.starIcon, labels: viewModel.conversation.labels)
        
        self.displayMessages(viewModel.conversation.messages)
        
        self.hideLoading()
    }
    
    func displayLoadError(viewModel: ConversationDetails.LoadError.ViewModel) {
        self.headerView.update(title: viewModel.conversation.title, starIcon: viewModel.conversation.starIcon, labels: viewModel.conversation.labels)
        
        self.displayMessages(viewModel.conversation.messages)
        
        if self.errorView == nil {
            self.errorView = ConversationsErrorView().with { view in
                view.delegate = self.delegate
            }
        }
        
        self.errorView?.isHidden = false
        self.errorView?.update(message: viewModel.message, button: viewModel.button)
        self.contentStackView.insertArrangedSubview(self.errorView!, at: 0)
        self.errorView?.snp.makeConstraints { make in
            make.width.equalToSuperview().multipliedBy(0.6)
        }
        
        self.hideLoading()
    }
    
    func showLoading() {
        guard self.spinnerView.superview == nil else { return }
        
        // Hide content
        self.scrollView.isHidden = true
        self.headerView.isHidden = true
        self.errorView?.isHidden = true
        
        // Show spinner
        self.spinnerView.startAnimation(nil)
        self.addSubview(self.spinnerView)
        self.spinnerView.snp.makeConstraints { make in
            make.centerY.equalToSuperview().multipliedBy(0.5)
            make.centerX.equalToSuperview()
        }
    }
    
    //
    // MARK: - Private
    //
    
    private func setupView() {
        self.headerView.with { headerView in
            headerView.isHidden = true
            self.addSubview(headerView)
            headerView.snp.makeConstraints { make in
                make.top.equalTo(self.safeArea.top)
                make.left.right.equalToSuperview().inset(16)
            }
            
            self.scrollView.with { scrollView in
                scrollView.automaticallyAdjustsContentInsets = false
                scrollView.contentInsets = NSEdgeInsets(top: 16, left: 0, bottom: 16, right: 0)
                self.addSubview(scrollView)
                scrollView.drawsBackground = false
                scrollView.snp.makeConstraints { make in
                    make.left.right.equalToSuperview()
                    make.top.equalTo(headerView.snp.bottom)
                    make.bottom.equalToSuperview()
                }
                
                self.contentStackView.with { stack in
                    stack.orientation = .vertical
                    stack.spacing = 16
                    stack.focusRingType = .none
                    stack.alignment = .centerX
                    scrollView.documentView = stack
                    stack.snp.makeConstraints { make in
                        make.top.left.right.equalTo(scrollView.contentView)
                    }
                }
            }
        }
        
        // Progress indicator
        self.spinnerView.with { view in
            view.style = .spinning
            view.isIndeterminate = true
            view.controlTint = .defaultControlTint
        }
    }
    
    private func displayMessages(_ messages: [Messages.Message.ViewModel]) {
        for view in self.contentStackView.subviews {
            view.removeFromSuperview()
        }
        
        for model in messages {
            let view = MessageDetailsView()
            view.delegate = self.delegate
            view.update(viewModel: model)
            self.contentStackView.addArrangedSubview(view)
            view.snp.makeConstraints { make in
                make.width.equalToSuperview().inset(20)
            }
        }
    }
    
    private func hideLoading() {
        // Show content
        self.scrollView.isHidden = false
        self.headerView.isHidden = false
        
        // Hide spinner
        self.spinnerView.stopAnimation(nil)
        self.spinnerView.removeFromSuperview()
    }
    
}
