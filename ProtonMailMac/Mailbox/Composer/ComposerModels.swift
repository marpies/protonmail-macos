//
//  ComposerModels.swift
//  ProtonMailMac
//
//  Created by Marcel Piešťanský on 26.11.2021.
//  Copyright (c) 2021 marpies. All rights reserved.
//

import Foundation
import AppKit

extension NSToolbarItem.Identifier {
    static let sendMail: NSToolbarItem.Identifier = NSToolbarItem.Identifier(rawValue: "SendMail")
    static let addAttachment: NSToolbarItem.Identifier = NSToolbarItem.Identifier(rawValue: "AddAttachment")
}

enum Composer {

	//
	// MARK: - Init
	//

	enum Init {
		struct Request {
		}

		struct Response {
		}

		struct ViewModel {
		}
	}
    
    //
    // MARK: - Update toolbar
    //
    
    enum UpdateToolbar {
        struct Response {
            let canSend: Bool
        }
        
        class ViewModel {
            let identifiers: [NSToolbarItem.Identifier]
            let items: [Main.ToolbarItem.ViewModel]
            
            init(identifiers: [NSToolbarItem.Identifier], items: [Main.ToolbarItem.ViewModel]) {
                self.identifiers = identifiers
                self.items = items
            }
        }
    }
    
}
