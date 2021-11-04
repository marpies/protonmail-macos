//
//  HumanVerificationMethod.swift
//  ProtonMailMac
//
//  Created by on 5/25/20.
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

public enum HumanVerificationMethod: String, CaseIterable {
    case captcha
    case sms
    case email
    case invite
    case payment
    case coupon
    
    public init?(rawValue: String) {
        switch rawValue {
        case "sms": self = .sms
        case "email": self = .email
        case "captcha": self = .captcha
        default:
            return nil
        }
    }
    var localizedTitle: String {
        switch self {
        case .sms:
            return "SMS"
        case .email:
            return "Email"
        case .captcha:
            return "CAPTCHA"
        default:
            return ""
        }
    }
}
