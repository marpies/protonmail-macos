//
//  HumanVerificationResponse.swift
//  ProtonMailMac
//
//  Created by Marcel Piešťanský on 01.11.2021.
//  Copyright © 2021 marpies. All rights reserved.
//

import Foundation

public class HumanVerificationResponse: Response {
    public var supported: [HumanVerificationMethod] = []
    public var startToken: String?
    
    public override func parseResponse (_ response: [String: Any]) -> Bool {
        if let details  = response["Details"] as? [String: Any] {
            if let hvToken = details["HumanVerificationToken"] as? String {
                startToken = hvToken
            }
            if let support = details["HumanVerificationMethods"] as? [String] {
                supported = support.compactMap { HumanVerificationMethod(rawValue: $0) }
            }
        }
        return true
    }
}
