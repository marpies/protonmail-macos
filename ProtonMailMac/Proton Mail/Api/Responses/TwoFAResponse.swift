//
//  TwoFAResponse.swift
//  ProtonMailMac
//
//  Created by Marcel Piešťanský on 26.08.2021.
//  Copyright © 2021 marpies. All rights reserved.
//

import Foundation

struct TwoFAResponse: Codable {
    var code: Int
    var scope: CredentialConvertible.Scope
}
