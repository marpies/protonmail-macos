//
//  ConversationTableCellView.swift
//  ProtonMailMac
//
//  Created by Marcel Piešťanský on 10.09.2021.
//  Copyright © 2021 marpies. All rights reserved.
//

import Cocoa

protocol ConversationTableCellViewDelegate: AnyObject {
    func conversationCellDidStarConversation(id: String, type: Conversations.TableItem.Kind)
    func conversationCellDidUnstarConversation(id: String, type: Conversations.TableItem.Kind)
}

class ConversationTableCellView: NSTableCellView, ImageButtonDelegate {
    
    private var unreadIndicationView: CircleView?
    private var foldersView: MessageFoldersView?
    
    private let mainStackView: NSStackView = NSStackView()
    private let titleStackView: NSStackView = NSStackView()
    private let subtitleStackView: NSStackView = NSStackView()
    
    private let titleLabel: NSTextField = NSTextField.asLabel
    private let subtitleLabel: NSTextField = NSTextField.asLabel
    private let dateLabel: NSTextField = NSTextField.asLabel
    private let favoriteButton: ImageButton = ImageButton()
    
    private var labelsView: MessageLabelsView?
    private var attachmentIcon: NSImageView?
    
    private(set) var id: String?
    private(set) var type: Conversations.TableItem.Kind?
    
    weak var delegate: ConversationTableCellViewDelegate?

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
    
    func update(viewModel: Conversations.TableItem.ViewModel) {
        self.id = viewModel.id
        self.type = viewModel.type
        
        self.titleLabel.stringValue = viewModel.title
        self.dateLabel.stringValue = viewModel.time
        self.subtitleLabel.stringValue = viewModel.subtitle
        
        self.updateStarIcon(viewModel: viewModel.starIcon)
        
        if let attachment = viewModel.attachmentIcon {
            self.addAttachmentIcon(viewModel: attachment)
        } else {
            self.removeAttachmentIcon()
        }
        
        if viewModel.isRead {
            self.removeUnreadIndicator()
        } else {
            self.addUnreadIndicator()
        }
        
        if let folders = viewModel.folders {
            self.addFoldersView(viewModel: folders)
        } else {
            self.removeFoldersView()
        }
        
        if let labels = viewModel.labels {
            self.addLabelsView(viewModel: labels)
        } else {
            self.removeLabelsView()
        }
    }
    
    //
    // MARK: - Private
    //
    
    private func updateStarIcon(viewModel: Messages.Star.ViewModel) {
        if #available(macOS 11.0, *) {
            self.favoriteButton.image = NSImage(systemSymbolName: viewModel.icon, accessibilityDescription: nil)
            self.favoriteButton.state = viewModel.isSelected ? .on : .off
        } else {
            // todo font icon
        }
        
        self.favoriteButton.contentTintColor = viewModel.color
        self.favoriteButton.toolTip = viewModel.tooltip
    }
    
    private func addAttachmentIcon(viewModel: Messages.Attachment.ViewModel) {
        if self.attachmentIcon == nil {
            if #available(macOS 11.0, *) {
                self.attachmentIcon = NSImageView(image: NSImage(systemSymbolName: viewModel.icon, accessibilityDescription: nil)!).with { view in
                    view.contentTintColor = .secondaryLabelColor
                    view.setContentHuggingPriority(NSLayoutConstraint.Priority(250), for: .horizontal)
                    self.subtitleStackView.addArrangedSubview(view)
                    view.snp.makeConstraints { make in
                        make.size.equalTo(20)
                    }
                }
            } else {
                // todo font icon
            }
        }
        
        self.attachmentIcon?.toolTip = viewModel.title
    }
    
    private func removeAttachmentIcon() {
        guard let view = self.attachmentIcon else { return }
        
        self.attachmentIcon = nil
        view.removeFromSuperview()
    }
    
    private func addLabelsView(viewModel: [Messages.Label.ViewModel]) {
        if self.labelsView == nil {
            self.labelsView = MessageLabelsView().with { stack in
                self.mainStackView.addArrangedSubview(stack)
            }
        }
        
        self.labelsView?.update(viewModel: viewModel)
    }
    
    private func removeLabelsView() {
        guard let view = self.labelsView else { return }
        
        self.labelsView = nil
        view.removeFromSuperview()
    }
    
    private func addFoldersView(viewModel: [Messages.Folder.ViewModel]) {
        if self.foldersView == nil {
            self.foldersView = MessageFoldersView().with { view in
                view.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
                view.setContentHuggingPriority(NSLayoutConstraint.Priority(200), for: .horizontal)
                self.subtitleStackView.insertArrangedSubview(view, at: 0)
            }
        }
        
        self.foldersView?.update(viewModel: viewModel)
    }
    
    private func removeFoldersView() {
        guard let view = self.foldersView else { return }
        
        self.foldersView = nil
        view.removeFromSuperview()
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
    
    private func setupView() {
        // Vertical stack
        self.mainStackView.with { vstack in
            vstack.orientation = .vertical
            vstack.spacing = 4
            vstack.alignment = .leading
            self.addSubview(vstack)
            vstack.snp.makeConstraints { make in
                make.left.right.equalToSuperview()
                make.centerY.equalToSuperview()
            }
            
            // First row stack
            self.titleStackView.with { stack in
                stack.orientation = .horizontal
                stack.spacing = 8
                stack.alignment = .centerY
                vstack.addArrangedSubview(stack)
            }
            
            // Second row stack
            self.subtitleStackView.with { stack in
                stack.orientation = .horizontal
                stack.spacing = 8
                vstack.addArrangedSubview(stack)
            }
            
            // Title label
            self.titleLabel.with { label in
                label.textColor = .labelColor
                label.lineBreakMode = .byTruncatingTail
                label.setPreferredFont(style: .headline)
                label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
                label.setContentHuggingPriority(NSLayoutConstraint.Priority(100), for: .horizontal)
                self.titleStackView.addArrangedSubview(label)
            }
            
            // Date label
            self.dateLabel.with { label in
                label.textColor = .secondaryLabelColor
                label.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
                label.setPreferredFont(style: .subheadline)
                label.setContentHuggingPriority(NSLayoutConstraint.Priority(120), for: .horizontal)
                self.titleStackView.addArrangedSubview(label)
            }
            
            self.favoriteButton.with { button in
                button.delegate = self
                button.setContentHuggingPriority(NSLayoutConstraint.Priority(140), for: .horizontal)
                self.titleStackView.addArrangedSubview(button)
            }
            
            // Subtitle
            self.subtitleLabel.with { label in
                label.textColor = .labelColor
                label.lineBreakMode = .byTruncatingTail
                label.setPreferredFont(style: .caption1)
                label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
                label.setContentHuggingPriority(NSLayoutConstraint.Priority(100), for: .horizontal)
                self.subtitleStackView.addArrangedSubview(label)
            }
        }
        
        // Hidden label for Big Sur to have the cell's separator expand over the entire cell's width
        // The separator seems to match the width of the last text field in the view hierarchy,
        // so if there is an image (e.g. folder icon), the separator is shorter
        if #available(macOS 11.0, *) {
            NSTextField.asLabel.with { label in
                label.isHidden = true
                self.addSubview(label)
                label.snp.makeConstraints { make in
                    make.left.right.equalTo(self.mainStackView)
                    make.bottom.equalTo(self.mainStackView)
                }
            }
        }
    }
    
    //
    // MARK: - Image button delegate
    //
    
    func imageButtonDidSelect(_ button: ImageButton) {
        guard let id = self.id, let type = self.type else { return }
        
        self.delegate?.conversationCellDidStarConversation(id: id, type: type)
    }
    
    func imageButtonDidDeselect(_ button: ImageButton) {
        guard let id = self.id, let type = self.type else { return }
        
        self.delegate?.conversationCellDidUnstarConversation(id: id, type: type)
    }
    
}
