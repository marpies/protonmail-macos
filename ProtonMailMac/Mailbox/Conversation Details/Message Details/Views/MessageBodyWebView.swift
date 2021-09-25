//
//  MessageBodyWebView.swift
//  ProtonMailMac
//
//  Created by Marcel Piešťanský on 22.09.2021.
//  Copyright © 2021 marpies. All rights reserved.
//

import Cocoa
import WebKit

class MessageBodyWebView: WKWebView {
    
    private let backgroundView: NSView = NSView()
    
    override func scrollWheel(with event: NSEvent) {
        self.nextResponder?.scrollWheel(with: event)
    }
    
}
