//
//  MessageDetailsHeaderView.swift
//  ProtonMailMac
//
//  Created by Marcel Piešťanský on 17.09.2021.
//  Copyright © 2021 marpies. All rights reserved.
//

import Cocoa
import SnapKit

protocol MessageDetailsHeaderViewDelegate: ImageButtonDelegate {
    func messageHeaderViewDidClick()
}

class MessageDetailsHeaderView: NSButton {
    
    private let titleStackView: NSStackView = NSStackView()
    private let titleLabel: NSTextField = NSTextField.asLabel
    private let dateLabel: NSTextField = NSTextField.asLabel
    private let foldersView: MessageFoldersView = MessageFoldersView()
    private let favoriteButton: ImageButton = ImageButton()
    private var repliedIcon: IconView?
    
    weak var delegate: MessageDetailsHeaderViewDelegate?

    init() {
        super.init(frame: .zero)
        
        self.translatesAutoresizingMaskIntoConstraints = false
        self.setupView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    //
    // MARK: - Public
    //
    
    func update(viewModel: Messages.Message.Header.ViewModel) {
        self.titleLabel.stringValue = viewModel.title
        self.foldersView.update(viewModel: viewModel.folders)
        self.dateLabel.stringValue = viewModel.date
        
        if let icon = viewModel.repliedIcon {
            self.addRepliedIcon(viewModel: icon)
        } else {
            self.removeRepliedIcon()
        }
        
        self.updateFavoriteButton(viewModel: viewModel.starIcon)
        
        self.favoriteButton.delegate = self.delegate
    }
    
    //
    // MARK: - Event handlers
    //
    
    @objc private func didClick() {
        self.delegate?.messageHeaderViewDidClick()
    }
    
    override func mouseDown(with event: NSEvent) {
        self.updateAlpha(0.5)
        
        super.mouseDown(with: event)
        
        self.updateAlpha(1)
    }
    
    //
    // MARK: - Private
    //
    
    private func setupView() {
        self.titleStackView.with { stack in
            stack.distribution = .fill
            stack.orientation = .horizontal
            stack.spacing = 8
            self.addSubview(stack)
            stack.snp.makeConstraints { make in
                make.edges.equalToSuperview().inset(16)
            }
        }
        
        self.titleLabel.with { label in
            label.isEnabled = false
            label.textColor = .labelColor
            label.setPreferredFont(style: .headline)
            label.setContentHuggingPriority(NSLayoutConstraint.Priority(100), for: .horizontal)
            self.titleStackView.addArrangedSubview(label)
        }
        
        NSView.spacer.with { spacer in
            self.titleStackView.addArrangedSubview(spacer)
        }
        
        self.foldersView.with { view in
            view.setContentHuggingPriority(.defaultHigh, for: .horizontal)
            self.titleStackView.addArrangedSubview(view)
        }
        
        self.dateLabel.with { label in
            label.isEnabled = false
            label.textColor = .secondaryLabelColor
            label.setPreferredFont(style: .subheadline)
            label.setContentHuggingPriority(NSLayoutConstraint.Priority(200), for: .horizontal)
            self.titleStackView.addArrangedSubview(label)
        }
        
        self.favoriteButton.with { button in
            button.setContentHuggingPriority(NSLayoutConstraint.Priority(140), for: .horizontal)
            self.titleStackView.addArrangedSubview(button)
        }
        
        self.imagePosition = .imageOnly
        self.isBordered = false
        self.target = self
        self.action = #selector(self.didClick)
    }
    
    private func addRepliedIcon(viewModel: Messages.Icon.ViewModel) {
        guard self.repliedIcon == nil else { return }
        
        self.repliedIcon = IconView().with { view in
            self.titleStackView.insertArrangedSubview(view, at: 1)
            view.update(icon: viewModel.icon, color: viewModel.color)
            view.toolTip = viewModel.tooltip
            view.snp.makeConstraints { make in
                make.size.equalTo(20)
            }
        }
    }
    
    private func removeRepliedIcon() {
        guard let view = self.repliedIcon else { return }
        
        self.repliedIcon = nil
        view.removeFromSuperview()
    }
    
    private func updateAlpha(_ value: CGFloat) {
        self.titleLabel.alphaValue = value
        self.foldersView.alphaValue = value
        self.dateLabel.alphaValue = value
        self.repliedIcon?.alphaValue = value
    }
    
    private func updateFavoriteButton(viewModel: Messages.Star.ViewModel) {
        if #available(macOS 11.0, *) {
            self.favoriteButton.image = NSImage(systemSymbolName: viewModel.icon, accessibilityDescription: nil)
            self.favoriteButton.state = viewModel.isSelected ? .on : .off
        } else {
            // todo font icon
        }
        
        self.favoriteButton.contentTintColor = viewModel.color
        self.favoriteButton.toolTip = viewModel.tooltip
    }
    
}
