//
//  SetupModels.swift
//  ProtonMailMac
//
//  Created by Marcel Piešťanský on 24.08.2021.
//  Copyright (c) 2021 marpies. All rights reserved.
//

import Foundation

enum Setup {

	//
	// MARK: - Init
	//

	enum Init {
		struct Request {
		}

		struct Response {
            let initialSection: App.Section
		}
	}
    
    //
    // MARK: - Launch content
    //
    
    enum LaunchContent {
        struct ViewModel {
            
        }
    }
    
}
