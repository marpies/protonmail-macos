//
//  TwoFactorInputView.swift
//  ProtonMailMac
//
//  Created by Marcel Piešťanský on 26.08.2021.
//  Copyright (c) 2021 marpies. All rights reserved.
//

import AppKit

protocol TwoFactorInputViewDelegate: AnyObject {
    func twoFactorConfirmButtonDidTap()
    func twoFactorCancelButtonDidTap()
}

class TwoFactorInputView: NSView, NSTextFieldDelegate {
    
    private let codeInput: NSTextField = PaddedTextField()
    
    weak var delegate: TwoFactorInputViewDelegate?
    
    var inputCode: String {
        return self.codeInput.stringValue
    }
    
    //
    // MARK: - Public
    //
    
    func displayData(viewModel: TwoFactorInput.Init.ViewModel) {
        let mainStack: NSStackView = NSStackView()
        mainStack.orientation = .vertical
        mainStack.alignment = .centerX
        mainStack.spacing = 8
        self.addSubview(mainStack)
        mainStack.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.equalToSuperview().multipliedBy(0.5)
        }
        
        NSTextField.asLabel.with { label in
            label.font = NSFont.preferredFont(forTextStyle: .largeTitle)
            label.stringValue = viewModel.title
            label.alignment = .center
            mainStack.addArrangedSubview(label)
        }
        
        NSView.spacer.with { spacer in
            mainStack.addArrangedSubview(spacer)
            spacer.snp.makeConstraints { make in
                make.height.equalTo(40)
            }
        }
        
        NSTextField.asLabel.with { label in
            label.setPreferredFont(style: .headline)
            label.stringValue = viewModel.fieldTitle
            label.textColor = NSColor.secondaryLabelColor
            mainStack.addArrangedSubview(label)
            label.snp.makeConstraints { make in
                make.width.equalToSuperview()
            }
        }
        
        self.codeInput.with { label in
            label.setPreferredFont(style: .body)
            label.textColor = NSColor.labelColor
            label.delegate = self
            label.contentType = .oneTimeCode
            mainStack.addArrangedSubview(label)
            label.snp.makeConstraints { make in
                make.width.equalToSuperview()
            }
        }
        
        NSView.spacer.with { spacer in
            mainStack.addArrangedSubview(spacer)
            spacer.snp.makeConstraints { make in
                make.height.equalTo(24)
            }
        }
        
        NSStackView().with { stack in
            stack.orientation = .horizontal
            stack.spacing = 16
            
            mainStack.addArrangedSubview(stack)
            
            // Cancel button
            NSButton().with { button in
                button.controlSize = .large
                button.title = viewModel.cancelButtonTitle
                button.bezelStyle = .rounded
                button.contentTintColor = NSColor.controlAccentColor
                button.target = self
                button.keyEquivalent = "\u{1b}"
                button.action = #selector(self.cancelButtonDidTap)
                stack.addArrangedSubview(button)
            }
            
            // Confirm button
            NSButton().with { button in
                button.controlSize = .large
                button.title = viewModel.confirmButtonTitle
                button.bezelStyle = .rounded
                button.contentTintColor = NSColor.controlAccentColor
                button.target = self
                button.keyEquivalent = "\r"
                button.action = #selector(self.confirmButtonDidTap)
                stack.addArrangedSubview(button)
            }
        }
    }
    
    func displayInvalidField(viewModel: TwoFactorInput.InvalidField.ViewModel) {
        self.codeInput.placeholderString = viewModel.placeholder
        self.codeInput.layer?.borderColor = NSColor.systemRed.cgColor
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
    
    @objc private func confirmButtonDidTap() {
        // Resign first responder temporarily to improve visual feedback in case of an invalid field error
        self.resignFirstResponder()
        
        self.delegate?.twoFactorConfirmButtonDidTap()
    }
    
    @objc private func cancelButtonDidTap() {
        self.delegate?.twoFactorCancelButtonDidTap()
    }

}
