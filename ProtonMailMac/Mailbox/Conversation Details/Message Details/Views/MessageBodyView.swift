//
//  MessageBodyView.swift
//  ProtonMailMac
//
//  Created by Marcel Piešťanský on 22.09.2021.
//  Copyright © 2021 marpies. All rights reserved.
//

import Cocoa
import SnapKit
import WebKit

protocol MessageBodyViewDelegate: AnyObject {
    func retryContentLoadButtonDidTap()
}

class MessageBodyView: NSView, BoxErrorViewDelegate, WebContentsSecureLoaderDelegate {
    
    private var spinnerView: NSProgressIndicator?
    private var errorView: BoxErrorView?
    private var webView: MessageBodyWebView?
    
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
    
    func showContent(viewModel: Messages.Message.Contents.ViewModel) {
        self.hideErrorView()
        
        self.initWebView(viewModel: viewModel)
        
        viewModel.loader.load(contents: viewModel.contents, in: self.webView!)
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
    
    func dispose() {
        self.hideLoading()
        self.webView?.stopLoading()
        self.webView?.configuration.userContentController.removeAllUserScripts()
        self.webView?.configuration.userContentController.removeScriptMessageHandler(forName: "loaded")
    }
    
    //
    // MARK: - Box error view delegate
    //
    
    func errorViewButtonDidTap() {
        self.delegate?.retryContentLoadButtonDidTap()
    }
    
    //
    // MARK: - Web loader delegate
    //
    
    func webContentsHeightDidUpdate(_ height: CGFloat) {
        self.hideLoading()
        self.webView?.isHidden = false
        
        guard let bounds = self.webView?.bounds, bounds.height != height else { return }
        
        self.webView?.snp.remakeConstraints { make in
            make.left.right.equalToSuperview().inset(1)
            make.top.equalToSuperview().offset(1)
            make.height.equalTo(height)
            make.bottom.equalToSuperview().inset(1).priority(.required)
        }
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
    
    private func initWebView(viewModel: Messages.Message.Contents.ViewModel) {
        guard self.webView == nil else { return }
        
        let preferences = WKPreferences()
        preferences.javaScriptCanOpenWindowsAutomatically = false
        
        let config: WKWebViewConfiguration = WKWebViewConfiguration()
        
        let loader: WebContentsSecureLoader = viewModel.loader
        loader.delegate = self
        loader.inject(into: config)
        
        config.preferences = preferences
        
        self.webView = MessageBodyWebView(frame: .zero, configuration: config).with { view in
            view.enclosingScrollView?.drawsBackground = false
            view.enclosingScrollView?.contentView.drawsBackground = false
            view.setValue(false, forKey: "drawsBackground")
            view.setContentCompressionResistancePriority(.required, for: .vertical)
            view.isHidden = true
            self.addSubview(view)
            view.snp.remakeConstraints { make in
                make.left.right.equalToSuperview().inset(1)
                make.top.equalToSuperview().offset(1)
                make.height.equalTo(1)
                make.bottom.equalToSuperview().inset(1).priority(.medium)
            }
        }
    }
    
}
