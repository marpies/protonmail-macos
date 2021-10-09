//
//  MailboxModels.swift
//  ProtonMailMac
//
//  Created by Marcel Piešťanský on 25.08.2021.
//  Copyright (c) 2021 marpies. All rights reserved.
//

import Foundation

enum Mailbox {

	//
	// MARK: - Init
	//

	enum Init {
		struct Request {
		}

		struct Response {
		}

		struct ViewModel {
            let loadingMessage: String
		}
	}
    
    //
    // MARK: - Load title
    //
    
    enum LoadTitle {
        struct Request {
            let labelId: String
        }
        
        struct Response {
            let item: MailboxSidebar.Item
            let numItems: Int
        }
        
        struct ViewModel {
            let title: String
            let subtitle: String?
        }
    }
    
}
