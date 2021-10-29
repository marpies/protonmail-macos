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
    func messageHeaderContactMenuItemDidTap(id: MenuItemIdentifier)
}

class MessageDetailsHeaderView: NSButton, MenuItemParsing {
    
    private let mainStackView: NSStackView = NSStackView()
    private let titleStackView: NSStackView = NSStackView()
    private let detailsStackView: NSStackView = NSStackView()
    private let titleLabel: NSTextField = NSTextField.asLabel
    private let dateLabel: NSTextField = NSTextField.asLabel
    private let foldersView: MessageFoldersView = MessageFoldersView()
    private let favoriteButton: ImageButton = ImageButton()
    
    private var labelsView: MessageLabelsView?
    private var draftLabelView: MessageLabelView?
    private var repliedIcon: IconView?
    private var unreadIndicationView: CircleView?
    
    private var viewModel: Messages.Message.Header.ViewModel?
    
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
        self.viewModel = viewModel
        
        self.titleLabel.stringValue = viewModel.title
        self.foldersView.update(viewModel: viewModel.folders)
        self.dateLabel.stringValue = viewModel.date
        
        if viewModel.isRead {
            self.removeUnreadIndicator()
        } else {
            self.addUnreadIndicator()
        }
        
        if let draft = viewModel.draftLabel {
            self.addDraftLabel(viewModel: draft)
        } else {
            self.removeDraftLabel()
        }
        
        if let icon = viewModel.repliedIcon {
            self.addRepliedIcon(viewModel: icon)
        } else {
            self.removeRepliedIcon()
        }
        
        if let labels = viewModel.labels {
            self.addLabelsView(viewModel: labels)
        } else {
            self.removeLabelsView()
        }
        
        self.updateFavoriteButton(viewModel: viewModel.starIcon)
        
        self.favoriteButton.delegate = self.delegate
    }
    
    func showDetails() {
        guard self.detailsStackView.superview == nil else { return }
        
        self.mainStackView.addArrangedSubview(self.detailsStackView)
        
        if let sentTo = self.viewModel?.sentTo {
            self.addContactGroup(viewModel: sentTo)
        }
        if let copyTo = self.viewModel?.copyTo {
            self.addContactGroup(viewModel: copyTo)
        }
        if let blindCopyTo = self.viewModel?.blindCopyTo {
            self.addContactGroup(viewModel: blindCopyTo)
        }
    }
    
    func hideDetails() {
        guard self.detailsStackView.superview != nil else { return }
        
        self.detailsStackView.removeFromSuperview()
        
        for view in self.detailsStackView.arrangedSubviews {
            view.removeFromSuperview()
        }
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
        self.mainStackView.with { stack in
            stack.alignment = .leading
            stack.orientation = .vertical
            stack.spacing = 8
            self.addSubview(stack)
            stack.snp.makeConstraints { make in
                make.edges.equalToSuperview().inset(16)
            }
        }
        
        self.titleStackView.with { stack in
            stack.distribution = .fill
            stack.orientation = .horizontal
            stack.spacing = 8
            self.mainStackView.addArrangedSubview(stack)
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
        
        self.detailsStackView.with { stack in
            stack.alignment = .leading
            stack.orientation = .vertical
            stack.spacing = 4
            
            // Only visible when expanded
        }
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
    
    private func addDraftLabel(viewModel: Messages.Label.ViewModel) {
        guard self.draftLabelView == nil else { return }
        
        self.draftLabelView = MessageLabelView().with { view in
            self.titleStackView.insertArrangedSubview(view, at: 1)
            view.update(viewModel: viewModel)
        }
    }
    
    private func removeDraftLabel() {
        guard let view = self.draftLabelView else { return }
        
        self.draftLabelView = nil
        view.removeFromSuperview()
    }
    
    private func addLabelsView(viewModel: [Messages.Label.ViewModel]) {
        if self.labelsView == nil {
            guard let index = self.titleStackView.arrangedSubviews.firstIndex(of: self.foldersView) else { return }
            
            self.labelsView = MessageLabelsView().with { view in
                self.titleStackView.insertArrangedSubview(view, at: index)
            }
        }
        
        self.labelsView?.update(viewModel: viewModel)
    }
    
    private func removeLabelsView() {
        guard let view = self.labelsView else { return }
        
        self.labelsView = nil
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
    
    private func addUnreadIndicator() {
        guard self.unreadIndicationView == nil else { return }
        
        self.unreadIndicationView = CircleView().with { view in
            self.titleStackView.insertArrangedSubview(view, at: 0)
            view.snp.makeConstraints { make in
                make.size.equalTo(6)
            }
        }
        
    }
    
    private func removeUnreadIndicator() {
        if let view = self.unreadIndicationView {
            self.unreadIndicationView = nil
            view.removeFromSuperview()
        }
    }
    
    private func addContactGroup(viewModel: Messages.Message.Header.ContactsGroup.ViewModel) {
        NSStackView().with { stack in
            stack.distribution = .fill
            stack.orientation = .horizontal
            stack.spacing = 4
            
            // Title label
            NSTextField.asLabel.with { label in
                label.setPreferredFont(style: .caption1)
                label.stringValue = viewModel.title
                label.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
                label.setContentHuggingPriority(.defaultHigh, for: .horizontal)
                stack.addArrangedSubview(label)
            }
            
            // Stacked buttons for contacts
            WrapStackView().with { view in
                view.spacing.x = 4
                view.spacing.y = 2
                view.setContentHuggingPriority(.defaultLow, for: .horizontal)

                // Items
                for item in viewModel.items {
                    NSMenuButton().with { button in
                        button.controlSize = .small
                        button.bezelStyle = .inline
                        button.title = item.title
                        button.menuOffset.x = 0
                        button.menuOffset.y = 6
                        button.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
                        
                        view.addSubview(button)
                        button.menu = NSMenu().with { menu in
                            menu.autoenablesItems = false
                            menu.items = item.menuItems.map { self.getMenuItem(model: $0, target: self, selector: #selector(self.contactsGroupItemMenuItemDidTap)) }
                        }
                    }
                }

                stack.addArrangedSubview(view)
            }
            
            self.detailsStackView.addArrangedSubview(stack)
        }
    }
    
    //
    // MARK: - Event handlers
    //
    
    @objc private func contactsGroupItemMenuItemDidTap(_ sender: Any) {
        if let item = sender as? IdentifiedNSMenuItem, let id = item.itemId {
            self.delegate?.messageHeaderContactMenuItemDidTap(id: id)
        }
    }
    
}
