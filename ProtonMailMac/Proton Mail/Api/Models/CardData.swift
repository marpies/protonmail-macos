//
//  CardData.swift
//  ProtonMail
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

// 0, 1, 2, 3 // 0 for cleartext, 1 for encrypted only (not used), 2 for signed, 3 for both
enum CardDataType : Int {
    case PlainText = 0
    case EncryptedOnly = 1
    case SignedOnly = 2
    case SignAndEncrypt = 3
}

// add contacts Card object
final class CardData : Package {
    let type : CardDataType
    let data : String
    let sign : String
    
    // t   "Type": CardDataType
    // d   "Data": ""
    // s   "Signature": ""
    init(t : CardDataType, d: String, s : String) {
        self.data = d
        self.type = t
        self.sign = s
    }
    
    var parameters: [String : Any]? {
        return [
            "Data": self.data,
            "Type": self.type.rawValue,
            "Signature": self.sign
        ]
    }
}
