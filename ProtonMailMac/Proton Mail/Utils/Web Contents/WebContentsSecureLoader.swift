//
//  HTMLSecureLoader.swift
//  ProtonMail - Created on 06/01/2019.
//
//
//  Copyright (c) 2019 Proton Technologies AG
//
//  This file is part of ProtonMail.
//
//  ProtonMail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ProtonMail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonMail.  If not, see <https://www.gnu.org/licenses/>.


import Foundation
import WebKit

protocol WebContentsSecureLoaderDelegate: AnyObject {
    func webContentsHeightDidUpdate(_ height: CGFloat)
}

protocol WebContentsSecureLoader: AnyObject {
    var delegate: WebContentsSecureLoaderDelegate? { get set }
    
    func load(contents: WebContents, in webView: WKWebView)
    func inject(into config: WKWebViewConfiguration)
}

extension WebContentsSecureLoader {
    static var domPurifyConfiguration: String {
        return """
        {
        ALLOWED_URI_REGEXP: /^(?:(?:(?:f|ht)tps?|mailto|tel|callto|cid|blob|xmpp|data):|[^a-z]|[a-z+.\\-]+(?:[^a-z+.\\-:]|$))/i,
        ADD_TAGS: ['proton-src', 'base'],
        ADD_ATTR: ['target', 'proton-src'],
        FORBID_TAGS: ['body', 'style', 'input', 'form', 'video', 'audio'],
        FORBID_ATTR: ['srcset']
        }
        """.replacingOccurrences(of: "\n", with: "")
    }
    
    func eject(from config: WKWebViewConfiguration) {
        config.userContentController.removeScriptMessageHandler(forName: "loaded")
    }
}
