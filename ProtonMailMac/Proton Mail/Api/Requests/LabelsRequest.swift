//
//  LabelsRequest.swift
//  ProtonMailMac
//
//  Created by Marcel Piešťanský on 27.08.2021.
//  Copyright © 2021 marpies. All rights reserved.
//

import Foundation

struct LabelsRequest: Request {
    let type: Int
    let authCredential: AuthCredential?
    
    let path: String = LabelsAPI.path
    let isAuth: Bool = true
    
    var parameters: [String: Any]? {
        return ["Type" : type]
    }
    
    init(type: LabelType, authCredential: AuthCredential) {
        self.type = type.rawValue
        self.authCredential = authCredential
    }
}
