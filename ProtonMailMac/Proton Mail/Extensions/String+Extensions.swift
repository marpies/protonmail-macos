//
//  StringExtension.swift
//  ProtonMail - Created on 2/23/15.
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
import Crypto

extension String {
    
    //TODO:: add test
    var publicKey : String  {
        var error: NSError?
        let key = CryptoNewKeyFromArmored(self, &error)
        if error != nil {
            return ""
        }
        
        return key?.getArmoredPublicKey(nil) ?? ""
    }
    
    var fingerprint : String {
        var error: NSError?
        let key = CryptoNewKeyFromArmored(self, &error)
        if error != nil {
            return ""
        }
        
        return key?.getFingerprint() ?? ""
    }
    
}

extension String {
    
    var armored : Bool {
        get {
            return self.hasPrefix("-----BEGIN PGP MESSAGE-----")
        }
    }
    
}


extension String {
    
    func decodeBase64() -> Data {
        let decodedData = Data(base64Encoded: self, options: NSData.Base64DecodingOptions(rawValue: 0))
        return decodedData!
    }
    
    func preg_replace_none_regex (_ partten: String, replaceto:String) -> String {
        return self.replacingOccurrences(of: partten, with: replaceto, options: NSString.CompareOptions.caseInsensitive, range: nil)
    }
    
    func preg_replace (_ partten: String, replaceto:String) -> String {
        let options : NSRegularExpression.Options = [.caseInsensitive, .dotMatchesLineSeparators]
        do {
            let regex = try NSRegularExpression(pattern: partten, options:options)
            let replacedString = regex.stringByReplacingMatches(in: self,
                                                                options: NSRegularExpression.MatchingOptions(rawValue: 0),
                                                                range: NSRange(location: 0, length: self.count),
                                                                withTemplate: replaceto)
            if !replacedString.isEmpty && replacedString.count > 0 {
                return replacedString
            }
        } catch let ex as NSError {
            PMLog.D("\(ex)")
        }
        return self
    }
    
    func preg_match (_ partten: String) -> Bool {
        let options : NSRegularExpression.Options = [.caseInsensitive, .dotMatchesLineSeparators]
        do {
            let regex = try NSRegularExpression(pattern: partten, options:options)
            return regex.firstMatch(in: self,
                                    options: NSRegularExpression.MatchingOptions(rawValue: 0),
                                    range: NSRange(location: 0, length: self.count)) != nil
        } catch let ex as NSError {
            PMLog.D("\(ex)")
        }
        
        return false
    }
    
    subscript (i: Int) -> Character {
        return self[self.index(self.startIndex, offsetBy: i)]
    }
    
    subscript (i: Int) -> String {
        return String(self[i] as Character)
    }
    
}

// MARK: - OpenPGP String extension

extension String {
    
    func decryptMessage(binKeys: [Data], passphrase: String) throws -> String? {
        return try Crypto().decrypt(encrytped: self, privateKey: binKeys, passphrase: passphrase)
    }
    
    func verifyMessage(verifier: [Data], binKeys: [Data], passphrase: String, time : Int64) throws -> ExplicitVerifyMessage? {
        return try Crypto().decryptVerify(encrytped: self, publicKey: verifier, privateKey: binKeys, passphrase: passphrase, verifyTime: time)
    }
    
    func verifyMessage(verifier: [Data], userKeys: [Data], keys: [Key], passphrase: String, time : Int64) throws -> ExplicitVerifyMessage? {
        var firstError : Error?
        for key in keys {
            do {
                if let token = key.token, let _ = key.signature { //have both means new schema. key is
                    if let plaitToken = try token.decryptMessage(binKeys: userKeys, passphrase: passphrase) {
                        //PMLog.D(signature)
                        return try Crypto().decryptVerify(encrytped: self,
                                                          publicKey: verifier,
                                                          privateKey: key.private_key,
                                                          passphrase: plaitToken, verifyTime: time)
                    }
                } else if let token = key.token { //old schema with token - subuser. key is embed singed
                    if let plaitToken = try token.decryptMessage(binKeys: userKeys, passphrase: passphrase) {
                        //TODO:: try to verify signature here embeded signature
                        return try Crypto().decryptVerify(encrytped: self,
                                                          publicKey: verifier,
                                                          privateKey: key.private_key,
                                                          passphrase: plaitToken, verifyTime: time)
                    }
                } else {//normal key old schema
                    return try Crypto().decryptVerify(encrytped: self,
                                                      publicKey: verifier,
                                                      privateKey: userKeys,
                                                      passphrase: passphrase, verifyTime: time)
                }
            } catch let error {
                if firstError == nil {
                    firstError = error
                }
                //PMLog.D(error.localizedDescription)
            }
        }
        if let error = firstError {
            throw error
        }
        return nil
    }
    
    func decryptMessageWithSinglKey(_ privateKey: String, passphrase: String) throws -> String? {
        return try Crypto().decrypt(encrytped: self, privateKey: privateKey, passphrase: passphrase)
    }
    
    func encrypt(withPrivKey key: String, mailbox_pwd: String) throws -> String? {
        return try Crypto().encrypt(plainText: self, privateKey: key, passphrase: mailbox_pwd)
    }
    
    func encrypt(withKey key: Key, userKeys: [Data], mailbox_pwd: String) throws -> String? {
        if let token = key.token, let _ = key.signature { //have both means new schema. key is
            if let plaitToken = try token.decryptMessage(binKeys: userKeys, passphrase: mailbox_pwd) {
                //PMLog.D(signature)
                return try Crypto().encrypt(plainText: self,
                                            publicKey: key.publicKey,
                                            privateKey: key.private_key,
                                            passphrase: plaitToken)
            }
        } else if let token = key.token { //old schema with token - subuser. key is embed singed
            if let plaitToken = try token.decryptMessage(binKeys: userKeys, passphrase: mailbox_pwd) {
                //TODO:: try to verify signature here embeded signature
                return try Crypto().encrypt(plainText: self,
                                            publicKey: key.publicKey,
                                            privateKey: key.private_key,
                                            passphrase: plaitToken)
            }
        }
        return try Crypto().encrypt(plainText: self,
                                    publicKey:  key.publicKey,
                                    privateKey: key.private_key,
                                    passphrase: mailbox_pwd)
    }
    
    func encrypt(withPubKey publicKey: String, privateKey: String, passphrase: String) throws -> String? {
        return try Crypto().encrypt(plainText: self, publicKey: publicKey, privateKey: privateKey, passphrase: passphrase)
    }
    
    func encrypt(withPwd passphrase: String) throws -> String? {
        return try Crypto().encrypt(plainText: self, token: passphrase)
    }
    
    func decrypt(withPwd passphrase: String) throws -> String? {
        return try Crypto().decrypt(encrypted: self, token: passphrase)
    }
}

extension String {
    
    func parseObjectAny() -> [String:Any]? {
        if self.isEmpty {
            return nil
        }
        do {
            let data : Data! = self.data(using: String.Encoding.utf8)
            let decoded = try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions.mutableContainers) as? [String:Any]
            return decoded
        } catch let ex as NSError {
            PMLog.D("\(ex)")
        }
        return nil
    }
    
    
    func parseJsonArray() -> [[String: Any]]? {
        if self.isEmpty {
            return []
        }
        
        do {
            if let data = self.data(using: String.Encoding.utf8) {
                return try JSONSerialization.jsonObject(with: data, options: []) as? [[String : Any]]
            }
        } catch let ex as NSError {
            PMLog.D(" func parseJson() -> error error \(ex)")
        }
        
        return nil
    }

}


extension String {
    
    /// A string with the special characters in it escaped.
    /// Used when passing a string into JavaScript, so the string is not completed too soon
    /// Performance is not good for large string - Notes from Feng
    var escaped: String {
        var arr = [String]()
        for u in self.utf16 {
            arr.append("\\u\(String(format: "%04X", u))")
        }
        let str = arr.joined()
        return str
    }
    
    func contains(check s: String) -> Bool {
        return self.range(of: s, options: NSString.CompareOptions.caseInsensitive) != nil ? true : false
    }
    
}


extension String {
    
    func parseObject() -> [String:String] {
        if self.isEmpty {
            return ["" : ""];
        }
        do {
            let data : Data! = self.data(using: String.Encoding.utf8)
            let decoded = try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions.mutableContainers) as? [String:String] ?? ["" : ""]
            return decoded
        } catch let ex as NSError {
            PMLog.D("\(ex)")
        }
        return ["":""]
    }
    
    func splitByComma() -> [String] {
        return self.components(separatedBy: ",")
    }
    
    func ln2br() -> String {
        let out = self.replacingOccurrences(of: "\r\n", with: "<br />")
        return out.replacingOccurrences(of: "\n", with: "<br />")
    }
    
    func rmln() -> String {
        return  self.replacingOccurrences(of: "\n", with: "")
    }
    
    func lr2lrln() -> String {
        return  self.replacingOccurrences(of: "\r", with: "\r\n")
    }
    
    func decodeHtml() -> String {
        var result = self.replacingOccurrences(of: "&amp;", with: "&", options: NSString.CompareOptions.caseInsensitive, range: nil)
        result = result.replacingOccurrences(of: "&quot;", with: "\"", options: NSString.CompareOptions.caseInsensitive, range: nil)
        result = result.replacingOccurrences(of: "&#039;", with: "'", options: NSString.CompareOptions.caseInsensitive, range: nil)
        result = result.replacingOccurrences(of: "&#39;", with: "'", options: NSString.CompareOptions.caseInsensitive, range: nil)
        result = result.replacingOccurrences(of: "&lt;", with: "<", options: NSString.CompareOptions.caseInsensitive, range: nil)
        result = result.replacingOccurrences(of: "&gt;", with: ">", options: NSString.CompareOptions.caseInsensitive, range: nil)
        return result
    }
    
    func encodeHtml() -> String {
        var result = self.replacingOccurrences(of: "&", with: "&amp;", options: .caseInsensitive, range: nil)
        result = result.replacingOccurrences(of: "\"", with: "&quot;", options: .caseInsensitive, range: nil)
        result = result.replacingOccurrences(of: "'", with: "&#039;", options: .caseInsensitive, range: nil)
        result = result.replacingOccurrences(of: "<br />", with: "\r\n", options: .caseInsensitive, range: nil)
        result = result.replacingOccurrences(of: "<br/>", with: "\r\n", options: .caseInsensitive, range: nil)
        result = result.replacingOccurrences(of: "<br>", with: "\r\n", options: .caseInsensitive, range: nil)
        result = result.replacingOccurrences(of: "<", with: "&lt;", options: .caseInsensitive, range: nil)
        result = result.replacingOccurrences(of: ">", with: "&gt;", options: .caseInsensitive, range: nil)
        result = result.replacingOccurrences(of: "\r\n", with: "<br />", options: .caseInsensitive, range: nil)
        return result
    }
    
    func stringBySetupInlineImage(_ from : String, to: String) -> String {
        return self.preg_replace_none_regex(from, replaceto:to)
    }
    
    func multipartGetHtmlContent() -> String {
        
        let textplainType = "text/plain".data(using: String.Encoding.utf8)
        let htmlType = "text/html".data(using: String.Encoding.utf8)
        
        guard
            var data = self.data(using: String.Encoding.utf8) as NSData?,
            var len = data.length as Int?
        else {
            return self.ln2br()
        }
        
        //get boundary=
        let boundarLine = "boundary=".data(using: String.Encoding.ascii)!
        let boundaryRange = data.range(of: boundarLine, options: NSData.SearchOptions.init(rawValue: 0), in: NSMakeRange(0, len))
        if boundaryRange.location == NSNotFound {
            return self.ln2br()
        }
        
        //new len
        len = len - (boundaryRange.location + boundaryRange.length);
        data = data.subdata(with: NSMakeRange(boundaryRange.location + boundaryRange.length, len)) as NSData
        let lineEnd = "\n".data(using: String.Encoding.ascii)!;
        let nextLine = data.range(of: lineEnd, options: NSData.SearchOptions.init(rawValue: 0), in: NSMakeRange(0, len))
        if nextLine.location == NSNotFound {
            return self.ln2br()
        }
        let boundary = data.subdata(with: NSMakeRange(0, nextLine.location))
        var boundaryString = NSString(data: boundary, encoding: String.Encoding.utf8.rawValue)!
        boundaryString = boundaryString.replacingOccurrences(of: "\"", with: "") as NSString
        boundaryString = boundaryString.replacingOccurrences(of: "\r", with: "") as NSString
        boundaryString = "--".appending(boundaryString as String) as NSString //+ boundaryString;
        
        len = len - (nextLine.location + nextLine.length);
        data = data.subdata(with: NSMakeRange(nextLine.location + nextLine.length, len)) as NSData
        
        var html : String = "";
        var plaintext : String = "";
        
        var count = 0;
        let nextBoundaryLine = boundaryString.data(using: String.Encoding.ascii.rawValue)!
        var firstboundaryRange = data.range(of: nextBoundaryLine, options: NSData.SearchOptions(rawValue: 0), in: NSMakeRange(0, len))
        
        if firstboundaryRange.location == NSNotFound {
            return self.ln2br()
        }
        
        while true {
            if count >= 10 {
                break;
            }
            count += 1;
            len = len - (firstboundaryRange.location + firstboundaryRange.length) - 1;
            data = data.subdata(with: NSMakeRange(1 + firstboundaryRange.location + firstboundaryRange.length, len)) as NSData
            
            if (data.subdata(with: NSMakeRange(0 , 1)) as NSData).isEqual(to: "-".data(using: String.Encoding.ascii)!) {
                break;
            }
            
            var bodyString = NSString(data: data as Data, encoding: String.Encoding.utf8.rawValue)
            
            let ContentEnd = data.range(of: lineEnd, options: NSData.SearchOptions(rawValue: 0), in: NSMakeRange(2, len - 2))
            if ContentEnd.location == NSNotFound {
                break
            }
            let contentType = data.subdata(with: NSMakeRange(0, ContentEnd.location)) as NSData
            len = len - (ContentEnd.location + ContentEnd.length);
            data = data.subdata(with: NSMakeRange(ContentEnd.location + ContentEnd.length, len)) as NSData
            
            bodyString = NSString(data: contentType as Data, encoding: String.Encoding.utf8.rawValue)!
            
            let EncodingEnd = data.range(of: lineEnd, options: NSData.SearchOptions(rawValue: 0), in: NSMakeRange(2, len - 2))
            if EncodingEnd.location == NSNotFound {
                break
            }
            let EncodingType = data.subdata(with: NSMakeRange(0, EncodingEnd.location))
            len = len - (EncodingEnd.location + EncodingEnd.length);
            data = data.subdata(with: NSMakeRange(EncodingEnd.location + EncodingEnd.length, len)) as NSData
            
            bodyString = NSString(data: EncodingType, encoding: String.Encoding.utf8.rawValue)!
            
            let secondboundaryRange = data.range(of: nextBoundaryLine, options: NSData.SearchOptions(rawValue: 0), in: NSMakeRange(0, len))
            if secondboundaryRange.location == NSNotFound {
                break
            }
            //get data
            let text = data.subdata(with: NSMakeRange(1, secondboundaryRange.location - 1))
            
            let plainFound = contentType.range(of: textplainType!, options: NSData.SearchOptions(rawValue: 0), in: NSMakeRange(0, contentType.length))
            if plainFound.location != NSNotFound {
                plaintext = NSString(data: text, encoding: String.Encoding.utf8.rawValue)! as String
            }
            
            let htmlFound = contentType.range(of: htmlType!, options: NSData.SearchOptions(rawValue: 0), in: NSMakeRange(0, contentType.length))
            if htmlFound.location != NSNotFound {
                html = NSString(data: text, encoding: String.Encoding.utf8.rawValue)! as String
            }
            
            // check html or plain text
            bodyString = NSString(data: text, encoding: String.Encoding.utf8.rawValue)!
            
            firstboundaryRange = secondboundaryRange
            
            PMLog.D(nstring: bodyString!)
        }
        
        if ( html.isEmpty && plaintext.isEmpty ) {
            return "<div><pre>" + self.rmln() + "</pre></div>"
        }
        
        return html.isEmpty ? plaintext.ln2br() : html
    }
    
    func hasRemoteContent() -> Bool {
        if self.preg_match("\\ssrc='(?!cid:)|\\ssrc=\"(?!cid:)|xlink:href=|poster=|background=|url\\(|url&#40;|url&#x28;|url&lpar;") {
            return true
        }
        return false
    }
    
}
