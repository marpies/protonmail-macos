//
//  RecaptchaView.swift
//  ProtonMailMac
//
//  Created by Marcel Piešťanský on 01.11.2021.
//  Copyright (c) 2021 marpies. All rights reserved.
//

import AppKit
import WebKit
import SnapKit

protocol RecaptchaViewDelegate: AnyObject {
    func captchaViewCloseButtonDidTap()
    func captchaChallengeDidPass(token: String)
}

class RecaptchaView: NSView, WKScriptMessageHandler {
    
    private var webView: WKWebView?
    
    weak var delegate: RecaptchaViewDelegate?
    
    //
    // MARK: - Public
    //
    
    func displayData(viewModel: Recaptcha.Init.ViewModel) {
        let preferences = WKPreferences()
        preferences.javaScriptEnabled = true
        preferences.javaScriptCanOpenWindowsAutomatically = true
        
        let config: WKWebViewConfiguration = WKWebViewConfiguration()
        config.preferences = preferences
        config.userContentController.add(self, name: "pm_message")
        
        // Override `postMessage` implementation to have ProtonMail web messages delivered here
        let source = """
        postMessage = function(message) {
            var str = JSON.stringify(message);
            window.webkit.messageHandlers.pm_message.postMessage(str);
        }
        """
        let script = WKUserScript(source: source, injectionTime: .atDocumentEnd, forMainFrameOnly: false)
        config.userContentController.addUserScript(script)
        
        self.webView = WKWebView(frame: .zero, configuration: config).with { view in
            self.addSubview(view)
            view.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
            
            view.load(viewModel.url)
        }
        
        // Close button
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
                button.image = NSImage.universal(name: viewModel.closeIcon)
                button.target = self
                button.action = #selector(self.closeButtonDidTap)
                
                view.addSubview(button)
                button.snp.makeConstraints { make in
                    make.edges.equalToSuperview().inset(4)
                }
            }
        }
    }
    
    /// Must be called to remove strong ref to this view within the web view.
    func dispose() {
        self.webView?.configuration.userContentController.removeAllUserScripts()
        self.webView?.configuration.userContentController.removeScriptMessageHandler(forName: "pm_message")
    }
    
    //
    // MARK: - WKScriptMessageHandler
    //
    
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard var body = message.body as? String else { return }
        
        body = body.replacingOccurrences(of: "\"{", with: "{")
        body = body.replacingOccurrences(of: "}\"", with: "}")
        body = body.replacingOccurrences(of: "\\\"", with: "\"")
        
        guard let dict: [String: Any] = body.parseObjectAny() else { return }
        
        if let type = dict.getString("type"), type == "pm_captcha", let token = dict.getString("token") {
            self.delegate?.captchaChallengeDidPass(token: token)
        }
    }
    
    //
    // MARK: - Private
    //
    
    @objc private func closeButtonDidTap() {
        self.delegate?.captchaViewCloseButtonDidTap()
    }

}
