//
//  Message+Vars.swift
//  ProtonMail - Created on 11/6/18.
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

extension Message {
    
    enum MimeType {
        static let html : String          = "text/html"
        static let plainText : String     = "text/plain"
        static let mutipartMixed : String = "multipart/mixed"
    }
    
    /// wrappers
    var cachedPassphrase: String? {
        get {
            guard let raw = self.cachedPassphraseRaw as Data? else { return nil }
            return String(data: raw, encoding: .utf8)
        }
        set { self.cachedPassphraseRaw = newValue?.data(using: .utf8) as NSData? }
    }
    
    var cachedAuthCredential: AuthCredential? {
        get { return AuthCredential.unarchive(data: self.cachedAuthCredentialRaw) }
        set { self.cachedAuthCredentialRaw = newValue?.archive() as NSData? }
    }
    var cachedUser: UserInfo? {
        get { return UserInfo.unarchive(self.cachedPrivateKeysRaw as Data?) }
        set { self.cachedPrivateKeysRaw = newValue?.archive() as NSData? }
    }
    var cachedAddress: Address? {
        get { return Address.unarchive(self.cachedAddressRaw as Data?) }
        set { self.cachedAddressRaw = newValue?.archive() as NSData? }
    }
    
    /// check if message starred
    var starred : Bool {
        get {
            return self.contains(label: .starred)
        }
    }
    
    /// check if message forwarded
    var forwarded : Bool {
        get {
            return self.flag.contains(.forwarded)
        }
        set {
            var flag = self.flag
            if newValue {
                flag.insert(.forwarded)
            } else {
                flag.remove(.forwarded)
            }
            self.flag = flag
        }
    }
    
    var sentSelf : Bool {
        get {
            return self.flag.contains(.sent) && self.flag.contains(.received)
        }
    }
    
    /// check if message contains a draft label
    var draft : Bool {
        get {
            return self.contains(label: "1") || self.contains(label: "8")
        }
    }
    
    /// get messsage label ids
    ///
    /// - Returns: array
    func getLabelIDs() -> [String] {
        var labelIDs = [String]()
        let labels = self.labels
        for l in labels {
            if let label = l as? Label {
                labelIDs.append(label.labelID)
            }
        }
        return labelIDs
    }
    
    func getNormalLabelIDs() -> [String] {
        var labelIDs = [String]()
        let labels = self.labels
        for l in labels {
            if let label = l as? Label, label.exclusive == false {
                if label.labelID.preg_match ("(?!^\\d+$)^.+$") {
                    labelIDs.append(label.labelID )
                }
            }
        }
        return labelIDs
    }
    
    /// get the lable IDs with the info about exclusive
    ///
    /// - Returns: dict
    func getLabelIDs() -> [String: Bool] {
        var out : [String : Bool] = [String : Bool]()
        let labels = self.labels
        for l in labels {
            if let label = l as? Label {
                out[label.labelID] = label.exclusive
            }
        }
        return out
    }
    
    /// check if message replied
    var replied : Bool {
        get {
            return self.flag.contains(.replied)
        }
        set {
            var flag = self.flag
            if newValue {
                flag.insert(.replied)
            } else {
                flag.remove(.replied)
            }
            self.flag = flag
        }
    }
    
    /// check if message replied to all
    var repliedAll : Bool {
        get {
            return self.flag.contains(.repliedAll)
        }
        set {
            var flag = self.flag
            if newValue {
                flag.insert(.repliedAll)
            } else {
                flag.remove(.repliedAll)
            }
            self.flag = flag
        }
    }
    
    /// this will check two type of sent folder
    var sentHardCheck : Bool {
        get {
            return self.contains(label: .outbox) || self.contains(label: "2")
        }
    }
    
    /// this will check two type of draft folder
    var draftHardCheck : Bool {
        get {
            return self.contains(label: .draft) || self.contains(label: "1")
        }
    }
    
    /// received and from protonmail internal
    var isInternal : Bool {
        get {
            return self.flag.contains(.internal) && self.flag.contains(.received)
        }
    }
    
    //signed mime also external message
    var isExternal : Bool {
        get {
            return !self.flag.contains(.internal) && self.flag.contains(.received)
        }
    }
    
    // 7  & 8
    var isE2E : Bool {
        get {
            return self.flag.contains(.e2e)
        }
    }
    
    //case outPGPInline = 7
    var isPgpInline : Bool {
        get {
            if isE2E, !isPgpMime {
                return true
            }
            return false
        }
    }
    
    //case outPGPMime = 8       // out pgp mime
    var isPgpMime : Bool {
        get {
            if let mt = self.mimeType, mt.lowercased() == Message.MimeType.mutipartMixed, isExternal, isE2E {
                return true
            }
            return false
        }
    }
    
    //case outSignedPGPMime = 9 //PGP/MIME signed message
    var isSignedMime : Bool {
        get {
            if let mt = self.mimeType, mt.lowercased() == Message.MimeType.mutipartMixed, isExternal, !isE2E {
                return true
            }
            return false
        }
    }
    
    var isPlainText : Bool {
        get {
            if let type = mimeType, (type.isEmpty || type.lowercased() == MimeType.plainText) {
                return true
            }
            return false
        }
        
    }
    
    var isMultipartMixed : Bool {
        get {
            if let type = mimeType, type.lowercased() == MimeType.mutipartMixed {
                return true
            }
            return false
        }
    }
    
}
