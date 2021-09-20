//
//  ConversationDetailsHeaderView.swift
//  ProtonMailMac
//
//  Created by Marcel Piešťanský on 17.09.2021.
//  Copyright © 2021 marpies. All rights reserved.
//

import Cocoa

protocol ConversationDetailsHeaderViewDelegate: AnyObject {
    func conversationFavoriteStatusDidChange(isOn: Bool)
}

class ConversationDetailsHeaderView: NSStackView, ImageButtonDelegate {
    
    private let titleLabel: NSTextField = NSTextField.asLabel
    private let favoriteButton: ImageButton = ImageButton()
    private var labelsView: MessageLabelsView?
    
    weak var headerDelegate: ConversationDetailsHeaderViewDelegate?

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
    
    func update(title: String, starIcon: Messages.Star.ViewModel, labels: [Messages.Label.ViewModel]?) {
        self.titleLabel.stringValue = title
        self.updateStarIcon(viewModel: starIcon)
        
        if let labels = labels {
            self.addLabelsView(viewModel: labels)
        } else {
            self.removeLabelsView()
        }
    }
    
    //
    // MARK: - Image button delegate
    //
    
    func imageButtonDidSelect(_ button: ImageButton) {
        self.headerDelegate?.conversationFavoriteStatusDidChange(isOn: true)
    }
    
    func imageButtonDidDeselect(_ button: ImageButton) {
        self.headerDelegate?.conversationFavoriteStatusDidChange(isOn: false)
    }
    
    //
    // MARK: - Private
    //
    
    private func setupView() {
        self.orientation = .vertical
        self.spacing = 8
        self.alignment = .leading
        
        // Title stack
        NSStackView().with { stack in
            stack.distribution = .fill
            stack.orientation = .horizontal
            stack.spacing = 8
            
            self.titleLabel.with { label in
                label.setPreferredFont(style: .title1)
                label.setContentHuggingPriority(.defaultLow, for: .horizontal)
                label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
                label.lineBreakMode = .byTruncatingTail
                label.textColor = .labelColor
                stack.addArrangedSubview(label)
            }
            
            self.favoriteButton.with { button in
                button.delegate = self
                button.setContentHuggingPriority(.defaultHigh, for: .horizontal)
                stack.addArrangedSubview(button)
            }
            
            self.addArrangedSubview(stack)
            stack.snp.makeConstraints { make in
                make.width.equalToSuperview()
            }
        }
        
        // Border
        NSView().with { view in
            view.wantsLayer = true
            view.layer?.backgroundColor = NSColor.separatorColor.cgColor
            self.addArrangedSubview(view)
            view.snp.makeConstraints { make in
                make.height.equalTo(1)
            }
        }
    }
    
    private func updateStarIcon(viewModel: Messages.Star.ViewModel) {
        if #available(macOS 11.0, *) {
            self.favoriteButton.image = NSImage(systemSymbolName: viewModel.icon, accessibilityDescription: nil)?.withSymbolConfiguration(NSImage.SymbolConfiguration(scale: .medium))
            self.favoriteButton.state = viewModel.isSelected ? .on : .off
        } else {
            // todo font icon
        }
        
        self.favoriteButton.contentTintColor = viewModel.color
        self.favoriteButton.toolTip = viewModel.tooltip
    }
    
    private func addLabelsView(viewModel: [Messages.Label.ViewModel]) {
        if self.labelsView == nil {
            self.labelsView = MessageLabelsView().with { view in
                self.insertArrangedSubview(view, at: 1)
            }
        }
        
        self.labelsView?.update(viewModel: viewModel)
    }
    
    private func removeLabelsView() {
        guard let view = self.labelsView else { return }
        
        self.labelsView = nil
        view.removeFromSuperview()
    }
    
}
