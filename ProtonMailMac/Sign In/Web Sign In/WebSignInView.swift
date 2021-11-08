//
//  WebSignInView.swift
//  ProtonMailMac
//
//  Created by Marcel Piešťanský on 04.11.2021.
//  Copyright (c) 2021 marpies. All rights reserved.
//

import AppKit
import WebKit
import SnapKit

protocol WebSignInViewDelegate: AnyObject {
    func signInCookiesDidUpdate(_ cookies: [HTTPCookie])
    func signInPasswordDidReceive(_ password: String, passwordMode: Int)
    func signInViewCloseButtonDidTap()
    func signInErrorAlertDidConfirm()
}

class WebSignInView: NSView, WKScriptMessageHandler {
    
    private var webView: WKWebView?
    private var loadingStackView: NSStackView?
    
    weak var delegate: WebSignInViewDelegate?
    
    //
    // MARK: - Public
    //
    
    func displayData(viewModel: WebSignIn.Init.ViewModel) {
        self.disposeLoadingStackView()
        
        let preferences = WKPreferences()
        preferences.javaScriptEnabled = true
        
        let config: WKWebViewConfiguration = WKWebViewConfiguration()
        config.preferences = preferences
        config.userContentController.add(self, name: "url_requests")
        
        let script = WKUserScript(source: viewModel.javaScript, injectionTime: .atDocumentStart, forMainFrameOnly: false)
        config.userContentController.addUserScript(script)
        
        self.webView = WKWebView(frame: .zero, configuration: config).with { view in
            self.addSubview(view)
            view.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
            
            view.load(viewModel.url)
        }
        
        self.addCloseButton(viewModel.closeIcon)
    }
    
    func displayLoading(viewModel: WebSignIn.DisplayLoading.ViewModel) {
        self.loadingStackView = NSStackView().with { stack in
            stack.orientation = .vertical
            stack.spacing = 8
            self.addSubview(stack)
            stack.snp.makeConstraints { make in
                make.center.equalToSuperview()
            }
            
            NSProgressIndicator().with { view in
                view.style = .spinning
                view.startAnimation(nil)
                stack.addArrangedSubview(view)
            }
            
            NSTextField.asLabel.with { label in
                label.setPreferredFont(style: .title3)
                label.stringValue = viewModel.message
                stack.addArrangedSubview(label)
            }
        }
    }
    
    func clearCookies(viewModel: WebSignIn.ClearCookies.ViewModel) {
        self.disposeWebView()
        self.clearCookies(forDomain: viewModel.domain)
    }
    
    func displaySignInError(viewModel: WebSignIn.SignInError.ViewModel) {
        guard let window = self.window else { return }
        
        // Show alert
        let alert = NSAlert()
        alert.messageText = viewModel.title
        alert.informativeText = viewModel.message
        alert.addButton(withTitle: viewModel.button)
        alert.alertStyle = .informational
        alert.beginSheetModal(for: window) { _ in
            self.delegate?.signInErrorAlertDidConfirm()
        }
    }
    
    func dispose() {
        self.disposeWebView()
    }
    
    //
    // MARK: - WKScriptMessageHandler
    //
    
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if let msg = message.body as? String, msg == "pm_cookie_response" {
            WKWebsiteDataStore.default().httpCookieStore.getAllCookies { cookies in
                self.delegate?.signInCookiesDidUpdate(cookies)
            }
        } else if let dict = message.body as? [String: Any] {
            if let password = dict.getString("password"), let passwordMode = dict.getInt("passwordMode") {
                self.delegate?.signInPasswordDidReceive(password, passwordMode: passwordMode)
            }
        }
    }
    
    //
    // MARK: - Private
    //
    
    private func addCloseButton(_ icon: String?) {
        guard let icon = icon else { return }
        
        AppearanceAdaptingView().with { view in
            view.backgroundColor = .controlBackgroundColor
            view.layer?.cornerRadius = 6
            self.addSubview(view)
            view.snp.makeConstraints { make in
                make.right.top.equalToSuperview().inset(8)
            }
            
            NSButton().with { button in
                button.imagePosition = .imageOnly
                button.bezelStyle = .texturedRounded
                button.image = NSImage.universal(name: icon)
                button.target = self
                button.action = #selector(self.closeButtonDidTap)
                
                view.addSubview(button)
                button.snp.makeConstraints { make in
                    make.edges.equalToSuperview().inset(4)
                }
            }
        }
    }
    
    private func disposeWebView() {
        self.webView?.stopLoading()
        self.webView?.removeFromSuperview()
        self.webView?.configuration.userContentController.removeAllUserScripts()
        self.webView?.configuration.userContentController.removeScriptMessageHandler(forName: "url_requests")
        self.webView = nil
    }
    
    private func disposeLoadingStackView() {
        guard let view = self.loadingStackView else { return }
        
        self.loadingStackView = nil
        
        view.removeFromSuperview()
    }
    
    private func clearCookies(forDomain domain: String) {
        WKWebsiteDataStore.default().httpCookieStore.getAllCookies { cookies in
            for cookie in cookies {
                if cookie.domain.contains(domain) {
                    WKWebsiteDataStore.default().httpCookieStore.delete(cookie, completionHandler: nil)
                }
            }
        }
    }
    
    @objc private func closeButtonDidTap() {
        self.delegate?.signInViewCloseButtonDidTap()
    }

}
