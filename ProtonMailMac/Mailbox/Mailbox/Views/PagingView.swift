//
//  PagingView.swift
//  ProtonMailMac
//
//  Created by Marcel Piešťanský on 31.10.2021.
//  Copyright © 2021 marpies. All rights reserved.
//

import Cocoa
import SnapKit

protocol PagingViewDelegate: AnyObject {
    func firstPageButtonDidTap()
    func previousPageButtonDidTap()
    func nextPageButtonDidTap()
    func lastPageButtonDidTap()
    func pageButtonDidTap(_ page: String)
}

/// Paging view to display page controls for the mailbox.
/// Not using `NSSegmentedControl`, since it does not support
/// displaying of images and text at the same time.
class PagingView: NSView {
    
    private let stackView: NSStackView = NSStackView()
    private let firstPageButton: NSButton = NSButton()
    private let prevPageButton: NSButton = NSButton()
    private let lastPageButton: NSButton = NSButton()
    private let nextPageButton: NSButton = NSButton()
    private var pageButtons: [NSButton] = []
    
    weak var delegate: PagingViewDelegate?
    
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
    
    func update(viewModel: Mailbox.PageCountUpdate.ViewModel) {
        self.firstPageButton.image = viewModel.firstPageIcon.image
        self.firstPageButton.toolTip = viewModel.firstPageIcon.tooltip
        self.prevPageButton.image = viewModel.previousPageIcon.image
        self.prevPageButton.toolTip = viewModel.previousPageIcon.tooltip
        self.nextPageButton.image = viewModel.nextPageIcon.image
        self.nextPageButton.toolTip = viewModel.nextPageIcon.tooltip
        self.lastPageButton.image = viewModel.lastPageIcon.image
        self.lastPageButton.toolTip = viewModel.lastPageIcon.tooltip
        
        self.firstPageButton.isEnabled = viewModel.previousButtonsEnabled
        self.prevPageButton.isEnabled = viewModel.previousButtonsEnabled
        self.nextPageButton.isEnabled = viewModel.nextButtonsEnabled
        self.lastPageButton.isEnabled = viewModel.nextButtonsEnabled
        
        self.pageButtons.forEach { $0.removeFromSuperview() }
        self.pageButtons.removeAll()
        
        var insertIndex: Int = 2
        for (index, page) in viewModel.pages.enumerated() {
            guard let title = page.title else { continue }
            
            let isActivePage: Bool = index == viewModel.selectedIndex
            let button: NSButton = NSButton()
            button.bezelStyle = .recessed
            button.title = title
            button.toolTip = page.tooltip
            button.isEnabled = !isActivePage
            button.target = self
            button.action = #selector(self.pageButtonDidTap)
            
            self.stackView.insertArrangedSubview(button, at: insertIndex)
            self.pageButtons.append(button)
            
            insertIndex += 1
        }
    }
    
    //
    // MARK: - Private
    //
    
    private func setupView() {
        self.stackView.with { stack in
            stack.setContentCompressionResistancePriority(.required, for: .vertical)
            stack.orientation = .horizontal
            self.addSubview(stack)
            stack.snp.makeConstraints { make in
                make.left.greaterThanOrEqualToSuperview()
                make.right.lessThanOrEqualToSuperview()
                make.centerX.equalToSuperview()
                make.top.bottom.equalToSuperview().inset(12)
            }
            
            // First page button
            self.initButton(self.firstPageButton)
            
            // Previous page button
            self.initButton(self.prevPageButton)
            
            // Next page button
            self.initButton(self.nextPageButton)
            
            // Last page button
            self.initButton(self.lastPageButton)
        }
        
        
        // Top border
        AppearanceAdaptingView().with { view in
            view.backgroundColor = NSColor(name: nil) { appearance in
                switch appearance.name {
                case .darkAqua, .vibrantDark, .accessibilityHighContrastDarkAqua, .accessibilityHighContrastVibrantDark:
                    return .black
                default:
                    return .separatorColor
                }
            }
            self.addSubview(view)
            view.snp.makeConstraints { make in
                make.left.right.top.equalToSuperview()
                make.height.equalTo(1)
            }
        }
    }
    
    private func initButton(_ button: NSButton) {
        button.bezelStyle = .recessed
        button.imagePosition = .imageOnly
        button.target = self
        button.action = #selector(self.imageButtonDidTap)
        self.stackView.addArrangedSubview(button)
    }
    
    @objc private func imageButtonDidTap(_ sender: NSButton) {
        if sender === self.firstPageButton {
            self.delegate?.firstPageButtonDidTap()
        } else if sender === self.prevPageButton {
            self.delegate?.previousPageButtonDidTap()
        } else if sender === self.nextPageButton {
            self.delegate?.nextPageButtonDidTap()
        } else if sender === self.lastPageButton {
            self.delegate?.lastPageButtonDidTap()
        }
    }
    
    @objc private func pageButtonDidTap(_ sender: NSButton) {
        self.delegate?.pageButtonDidTap(sender.title)
    }
    
}
