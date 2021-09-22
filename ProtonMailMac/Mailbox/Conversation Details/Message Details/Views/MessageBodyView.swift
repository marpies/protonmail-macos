//
//  MessageBodyView.swift
//  ProtonMailMac
//
//  Created by Marcel Piešťanský on 22.09.2021.
//  Copyright © 2021 marpies. All rights reserved.
//

import Cocoa
import SnapKit

protocol MessageBodyViewDelegate: AnyObject {
    func retryContentLoadButtonDidTap()
}

class MessageBodyView: NSView, BoxErrorViewDelegate {
    
    private var spinnerView: NSProgressIndicator?
    private var errorView: BoxErrorView?
    
    weak var delegate: MessageBodyViewDelegate?
    
    init() {
        super.init(frame: .zero)
        
        self.setupView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func showLoading() {
        guard self.spinnerView == nil else { return }
        
        self.hideErrorView()
        
        self.spinnerView = NSProgressIndicator().with { view in
            view.style = .spinning
            view.isIndeterminate = true
            view.controlTint = .defaultControlTint
            view.startAnimation(nil)
            view.setContentCompressionResistancePriority(.required, for: .vertical)
            self.addSubview(view)
            view.snp.makeConstraints { make in
                make.centerX.equalToSuperview()
                make.top.bottom.equalToSuperview().inset(24)
            }
        }
    }
    
    func showContent(_ value: String) {
        self.hideLoading()
        self.hideErrorView()
        
        // todo show content
    }
    
    func showErrorContent(message: String, button: String) {
        self.hideLoading()
        
        guard self.errorView == nil else { return }
        
        self.errorView = BoxErrorView().with { view in
            view.delegate = self
            view.update(message: message, button: button)
            self.addSubview(view)
            view.snp.makeConstraints { make in
                make.edges.equalToSuperview().inset(16)
            }
        }
    }
    
    //
    // MARK: - Box error view delegate
    //
    
    func errorViewButtonDidTap() {
        self.delegate?.retryContentLoadButtonDidTap()
    }
    
    //
    // MARK: - Private
    //
    
    private func setupView() {
        NSView().with { border in
            border.wantsLayer = true
            border.layer?.backgroundColor = NSColor.separatorColor.cgColor
            self.addSubview(border)
            border.snp.makeConstraints { make in
                make.top.equalToSuperview()
                make.left.right.equalToSuperview().inset(1)
                make.height.equalTo(1)
            }
        }
    }
    
    private func hideLoading() {
        guard let view = self.spinnerView else { return }
        
        self.spinnerView = nil
        view.stopAnimation(nil)
        view.removeFromSuperview()
    }
    
    private func hideErrorView() {
        self.errorView?.removeFromSuperview()
        self.errorView = nil
    }
    
}
