//
//  SignInView.swift
//  ProtonMailMac
//
//  Created by Marcel Piešťanský on 25.08.2021.
//  Copyright (c) 2021 marpies. All rights reserved.
//

import AppKit
import SnapKit

protocol SignInViewDelegate: AnyObject {
    func signInButtonDidTap()
    func signInCancelButtonDidTap()
}

class SignInView: NSView, NSTextFieldDelegate {
    
    private let mainStack: NSStackView = NSStackView()
    private let buttonStack: NSStackView = NSStackView()
    private var cancelButton: NSButton?
    private let signInButton: NSButton = NSButton()
    private let usernameInput: NSTextField = PaddedTextField()
    private let passwordInput: NSTextField = PaddedSecureTextField()
    private var progressView: NSProgressIndicator?
    
    var username: String {
        return self.usernameInput.stringValue
    }
    
    var password: String {
        return self.passwordInput.stringValue
    }
    
    weak var delegate: SignInViewDelegate?
    
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
    
    func displayData(viewModel: SignIn.Init.ViewModel) {
        NSTextField.asLabel.with { label in
            label.font = NSFont.preferredFont(forTextStyle: .largeTitle)
            label.stringValue = viewModel.title
            label.alignment = .center
            self.mainStack.addArrangedSubview(label)
        }
        
        NSView.spacer.with { spacer in
            self.mainStack.addArrangedSubview(spacer)
            spacer.snp.makeConstraints { make in
                make.height.equalTo(40)
            }
        }
        
        NSTextField.asLabel.with { label in
            label.setPreferredFont(style: .headline)
            label.stringValue = viewModel.usernameTitle
            label.textColor = NSColor.secondaryLabelColor
            self.mainStack.addArrangedSubview(label)
            label.snp.makeConstraints { make in
                make.width.equalToSuperview()
            }
        }
        
        self.usernameInput.with { label in
            label.setPreferredFont(style: .body)
            label.textColor = NSColor.labelColor
            label.delegate = self
            self.mainStack.addArrangedSubview(label)
            label.snp.makeConstraints { make in
                make.width.equalToSuperview()
            }
        }
        
        NSView.spacer.with { spacer in
            self.mainStack.addArrangedSubview(spacer)
            spacer.snp.makeConstraints { make in
                make.height.equalTo(8)
            }
        }
        
        NSTextField.asLabel.with { label in
            label.setPreferredFont(style: .headline)
            label.stringValue = viewModel.passwordTitle
            label.textColor = NSColor.secondaryLabelColor
            self.mainStack.addArrangedSubview(label)
            label.snp.makeConstraints { make in
                make.width.equalToSuperview()
            }
        }
        
        self.passwordInput.with { label in
            label.setPreferredFont(style: .body)
            label.textColor = NSColor.labelColor
            label.delegate = self
            self.mainStack.addArrangedSubview(label)
            label.snp.makeConstraints { make in
                make.width.equalToSuperview()
            }
        }
        
        NSView.spacer.with { spacer in
            self.mainStack.addArrangedSubview(spacer)
            spacer.snp.makeConstraints { make in
                make.height.equalTo(24)
            }
        }
        
        self.mainStack.addArrangedSubview(self.buttonStack)
        
        // Cancel button
        if let title = viewModel.cancelButtonTitle {
            self.cancelButton = NSButton().with { button in
                button.controlSize = .large
                button.title = title
                button.bezelStyle = .rounded
                button.contentTintColor = NSColor.controlAccentColor
                button.target = self
                button.keyEquivalent = "\u{1b}"
                button.action = #selector(self.signInCancelButtonDidTap)
                self.buttonStack.addArrangedSubview(button)
            }
        }
        
        self.signInButton.with { button in
            button.controlSize = .large
            button.title = viewModel.signInButtonTitle
            button.bezelStyle = .rounded
            button.contentTintColor = NSColor.controlAccentColor
            button.target = self
            button.keyEquivalent = "\r"
            button.action = #selector(self.signInButtonDidTap)
            self.buttonStack.addArrangedSubview(button)
        }
    }
    
    func displaySignInDidBegin() {
        self.buttonStack.removeFromSuperview()
        self.usernameInput.isEnabled = false
        self.passwordInput.isEnabled = false
        
        self.progressView = NSProgressIndicator().with { view in
            view.style = .spinning
            view.startAnimation(nil)
            self.mainStack.addArrangedSubview(view)
        }
    }
    
    func displaySignInError(viewModel: SignIn.SignInError.ViewModel) {
        guard let window = self.window else { return }
        
        // Show alert
        let alert = NSAlert()
        alert.messageText = viewModel.title
        alert.informativeText = viewModel.message
        alert.addButton(withTitle: viewModel.button)
        alert.alertStyle = .informational
        alert.beginSheetModal(for: window, completionHandler: nil)
        
        self.cancelLoading()
    }
    
    func displayInvalidField(viewModel: SignIn.InvalidField.ViewModel) {
        let input: NSTextField
        
        switch viewModel.type {
        case .username:
            input = self.usernameInput
        case .password:
            input = self.passwordInput
        }
        
        input.placeholderString = viewModel.placeholder
        input.layer?.borderColor = NSColor.systemRed.cgColor
    }
    
    func displaySignInDidCancel() {
        self.cancelLoading()
        
        // Remove password
        self.passwordInput.stringValue = ""
    }
    
    //
    // MARK: - Text field delegate
    //
    
    func controlTextDidBeginEditing(_ obj: Notification) {
        guard let textField = obj.object as? NSTextField else { return }
        
        // Remove potential error highlighting
        textField.placeholderString = nil
        textField.layer?.borderColor = NSColor.separatorColor.cgColor
    }
    
    //
    // MARK: - Private
    //
    
    private func setupView() {
        self.mainStack.orientation = .vertical
        self.mainStack.alignment = .centerX
        self.mainStack.spacing = 8
        self.addSubview(self.mainStack)
        self.mainStack.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.equalToSuperview().multipliedBy(0.5)
        }
        
        self.buttonStack.with { stack in
            stack.orientation = .horizontal
            stack.spacing = 16
        }
    }
    
    private func cancelLoading() {
        guard let progressView = self.progressView else { return }
        
        // Remove progress view and show button(s) again
        progressView.removeFromSuperview()
        self.progressView = nil
        
        self.mainStack.addArrangedSubview(self.buttonStack)
        
        // Re-enable text inputs
        self.usernameInput.isEnabled = true
        self.passwordInput.isEnabled = true
    }
    
    @objc private func signInButtonDidTap() {
        // Resign first responder temporarily to improve visual feedback in case of an invalid field error
        self.resignFirstResponder()
        
        self.delegate?.signInButtonDidTap()
    }
    
    @objc private func signInCancelButtonDidTap() {
        self.delegate?.signInCancelButtonDidTap()
    }
    
}
