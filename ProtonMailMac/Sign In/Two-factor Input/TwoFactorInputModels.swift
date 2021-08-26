//
//  TwoFactorInputModels.swift
//  ProtonMailMac
//
//  Created by Marcel Piešťanský on 26.08.2021.
//  Copyright (c) 2021 marpies. All rights reserved.
//

import Foundation

enum TwoFactorInput {
    
    enum Error {
        case emptyInput
    }

	//
	// MARK: - Init
	//

	enum Init {
		struct Request {
		}

		struct Response {
		}

		class ViewModel {
            let title: String
            let fieldTitle: String
            let confirmButtonTitle: String
            let cancelButtonTitle: String

            init(title: String, fieldTitle: String, confirmButtonTitle: String, cancelButtonTitle: String) {
                self.title = title
                self.fieldTitle = fieldTitle
                self.confirmButtonTitle = confirmButtonTitle
                self.cancelButtonTitle = cancelButtonTitle
            }
		}
	}
    
    //
    // MARK: - Process input
    //
    
    enum ProcessInput {
        struct Request {
            let input: String
        }
        
        struct Response {
            let error: TwoFactorInput.Error
        }
    }
    
    //
    // MARK: - Invalid field
    //
    
    enum InvalidField {
        struct ViewModel {
            let placeholder: String
        }
    }
    
}
