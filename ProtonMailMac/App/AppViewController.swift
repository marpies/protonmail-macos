//
//  AppViewController.swift
//  ProtonMailMac
//
//  Created by Marcel Piešťanský on 25.08.2021.
//  Copyright © 2021 marpies. All rights reserved.
//

import Cocoa
import AppKit
import SnapKit
import Swinject

class AppViewController: NSViewController {
    
    private let resolver: Resolver
    
    private var currentSection: NSViewController? {
        didSet {
            guard let toolbarUtilizing = self.currentSection as? ToolbarUtilizing else { return }
            
            toolbarUtilizing.toolbarDelegate = self.toolbarDelegate
        }
    }
    
    weak var toolbarDelegate: ToolbarUtilizingDelegate?
    
    init(resolver: Resolver) {
        self.resolver = resolver
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        self.view = NSView()
        self.view.wantsLayer = true
        self.view.layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.frame = NSRect(origin: .zero, size: CGSize.defaultWindow)
        
        // Display initial section
        self.displaySection(self.resolver.resolve(SetupViewController.self)!)
    }
    
    func displaySection(_ vc: NSViewController) {
        if let current = self.currentSection {
            self.currentSection = vc
            self.addChild(vc)
            self.transition(from: current, to: vc, options: .crossfade) {
                current.removeFromParent()
            }
            vc.view.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
            return
        }
        
        self.addChild(vc)
        self.view.addSubview(vc.view)
        vc.view.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        self.currentSection = vc
    }
    
}
