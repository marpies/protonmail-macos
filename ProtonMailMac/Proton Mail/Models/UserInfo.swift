import Foundation
import Crypto

public struct ShowImages: OptionSet {
    public init(rawValue: Int) {
        self.rawValue = rawValue
    }
    
    public let rawValue: Int
    // 0 for none, 1 for remote, 2 for embedded, 3 for remote and embedded (
    
    public static let none     = ShowImages([])
    public static let remote   = ShowImages(rawValue: 1 << 0) // auto load remote images
    public static let embedded = ShowImages(rawValue: 1 << 1) // auto load embedded images
}

public enum LinkOpeningMode: String {
    case confirmationAlert, openAtWill
}

public final class UserInfo: NSObject {
    
    // 1.9.0 phone local cache
    public var language: String
    
    // 1.9.1 user object
    public var delinquent: Int
    public var role: Int
    public var maxSpace: Int64
    public var usedSpace: Int64
    public var maxUpload: Int64
    public var userId: String
    
    public var userKeys: [Key] // user key
    
    // 1.11.12 user object
    public var credit: Int
    public var currency: String
    
    // 1.9.1 mail settings
    public var displayName: String = ""
    public var defaultSignature: String = ""
    public var autoSaveContact: Int = 0
    public var showImages: ShowImages = .none
    public var autoShowRemote: Bool {
        return self.showImages.contains(.remote)
    }
    public var swipeLeft: Int = 3
    public var swipeRight: Int = 0
    
    public var linkConfirmation: LinkOpeningMode = .confirmationAlert
    
    public var attachPublicKey: Int = 0
    public var sign: Int = 0
    
    // 1.9.1 user settings
    public var notificationEmail: String = ""
    public var notify: Int = 0
    
    // 1.9.0 get from addresses route
    public var userAddresses: [Address] = [Address]()
    
    // 1.12.0
    public var passwordMode: Int = 1
    public var twoFactor: Int = 0
    
    // 2.0.0
    public var enableFolderColor: Int = 0
    public var inheritParentFolderColor: Int = 0
    /// 0: free user, > 0: paid user
    public var subscribed: Int = 0
    
    // 0 - threading, 1 - single message
    public var groupingMode: Int = 0
    
    public static func getDefault() -> UserInfo {
        return .init(maxSpace: 0, usedSpace: 0, language: "",
                     maxUpload: 0, role: 0, delinquent: 0,
                     keys: nil, userId: "", linkConfirmation: 0,
                     credit: 0, currency: "", subscribed: 0)
    }
    
    public var isPaid: Bool {
        return self.role > 0 ? true : false
    }
    
    // init from cache
    public required init(
        displayName: String?, maxSpace: Int64?, notificationEmail: String?, signature: String?,
        usedSpace: Int64?, userAddresses: [Address]?,
        autoSC: Int?, language: String?, maxUpload: Int64?, notify: Int?, showImage: Int?,  // v1.0.8
        swipeL: Int?, swipeR: Int?,  // v1.1.4
        role: Int?,
        delinquent: Int?,
        keys: [Key]?,
        userId: String?,
        sign: Int?,
        attachPublicKey: Int?,
        linkConfirmation: String?,
        credit: Int?,
        currency: String?,
        pwdMode: Int?,
        twoFA: Int?,
        enableFolderColor: Int?,
        inheritParentFolderColor: Int?,
        subscribed: Int?) {
        self.maxSpace = maxSpace ?? 0
        self.usedSpace = usedSpace ?? 0
        self.language = language ?? "en_US"
        self.maxUpload = maxUpload ?? 0
        self.role = role ?? 0
        self.delinquent = delinquent ?? 0
        self.userKeys = keys ?? [Key]()
        self.userId = userId ?? ""
        
        // get from user settings
        self.notificationEmail = notificationEmail ?? ""
        self.notify = notify ?? 0
        
        // get from mail settings
        self.displayName = displayName ?? ""
        self.defaultSignature = signature ?? ""
        self.autoSaveContact  = autoSC ?? 0
        self.showImages = ShowImages(rawValue: showImage ?? 0)
        self.swipeLeft = swipeL ?? 3
        self.swipeRight = swipeR ?? 0
        
        self.sign = sign ?? 0
        self.attachPublicKey = attachPublicKey ?? 0
        
        // addresses
        self.userAddresses = userAddresses ?? [Address]()
        
        self.credit = credit ?? 0
        self.currency = currency ?? "USD"
        
        self.passwordMode = pwdMode ?? 1
        self.twoFactor = twoFA ?? 0
        
        self.enableFolderColor = enableFolderColor ?? 0
        self.inheritParentFolderColor = inheritParentFolderColor ?? 0
        self.subscribed = subscribed ?? 0
        if let value = linkConfirmation, let mode = LinkOpeningMode(rawValue: value) {
            self.linkConfirmation = mode
        }
    }
    
    // init from api
    public required init(maxSpace: Int64?, usedSpace: Int64?,
                         language: String?, maxUpload: Int64?,
                         role: Int?,
                         delinquent: Int?,
                         keys: [Key]?,
                         userId: String?,
                         linkConfirmation: Int?,
                         credit: Int?,
                         currency: String?,
                         subscribed: Int?) {
        self.maxSpace = maxSpace ?? 0
        self.usedSpace = usedSpace ?? 0
        self.language = language ?? "en_US"
        self.maxUpload = maxUpload ?? 0
        self.role = role ?? 0
        self.delinquent = delinquent ?? 0
        self.userId = userId ?? ""
        self.userKeys = keys ?? [Key]()
        self.linkConfirmation = linkConfirmation == 0 ? .openAtWill : .confirmationAlert
        self.credit = credit ?? 0
        self.currency = currency ?? "USD"
        self.subscribed = subscribed ?? 0
    }
    
    /// Update user addresses
    ///
    /// - Parameter addresses: new addresses
    public func set(addresses: [Address]) {
        self.userAddresses = addresses
    }
    
    /// set User, copy the data from input user object
    ///
    /// - Parameter userinfo: New user info
    public func set(userinfo: UserInfo) {
        self.maxSpace = userinfo.maxSpace
        self.usedSpace = userinfo.usedSpace
        self.language = userinfo.language
        self.maxUpload = userinfo.maxUpload
        self.role = userinfo.role
        self.delinquent = userinfo.delinquent
        self.userId = userinfo.userId
        self.linkConfirmation = userinfo.linkConfirmation
        self.userKeys = userinfo.userKeys
    }
    
    public func parse(userSettings: [String: Any]?) {
        if let settings = userSettings {
            if let email = settings["Email"] as? [String: Any] {
                self.notificationEmail = email["Value"] as? String ?? ""
                self.notify = email["Notify"] as? Int ?? 0
            }
            
            if let pwdMode = settings["PasswordMode"] as? Int {
                self.passwordMode = pwdMode
            } else {
                if let pwd = settings["Password"] as? [String: Any] {
                    if let mode = pwd["Mode"] as? Int {
                        self.passwordMode = mode
                    }
                }
            }
            
            if let twoFA = settings["2FA"]  as? [String: Any] {
                self.twoFactor = twoFA["Enabled"] as? Int ?? 0
            }
        }
    }
    
    public func parse(mailSettings: [String: Any]?) {
        if let settings = mailSettings {
            self.displayName = settings["DisplayName"] as? String ?? "'"
            self.defaultSignature = settings["Signature"] as? String ?? ""
            self.autoSaveContact  = settings["AutoSaveContacts"] as? Int ?? 0
            self.showImages = ShowImages(rawValue: settings["ShowImages"] as? Int ?? 0)
            self.swipeLeft = settings["SwipeLeft"] as? Int ?? 3
            self.swipeRight = settings["SwipeRight"] as? Int ?? 0
            self.linkConfirmation = settings["ConfirmLink"] as? Int == 0 ? .openAtWill : .confirmationAlert
            
            self.attachPublicKey = settings["AttachPublicKey"] as? Int ?? 0
            self.sign = settings["Sign"] as? Int ?? 0
            self.enableFolderColor = settings["EnableFolderColor"] as? Int ?? 0
            self.inheritParentFolderColor = settings["InheritParentFolderColor"] as? Int ?? 0
            self.groupingMode = settings["ViewMode"] as? Int ?? 0
        }
    }
    
    public func firstUserKey() -> Key? {
        if self.userKeys.count > 0 {
            return self.userKeys[0]
        }
        return nil
    }
    
    public func getPrivateKey(by keyID: String?) -> String? {
        if let keyID = keyID {
            for userkey in self.userKeys where userkey.key_id == keyID {
                return userkey.private_key
            }
        }
        return firstUserKey()?.private_key
    }
    
    public var newSchema: Bool {
        for key in addressKeys where key.newSchema {
            return true
        }
        return false
    }
    
    public var addressKeys: [Key] {
        var out = [Key]()
        for addr in userAddresses {
            for key in addr.keys {
                out.append(key)
            }
        }
        return out
    }
    
    //    var addressPrivateKeys: Data {
    ////        var out = Data()
    ////        var error: NSError?
    ////        for addr in userAddresses {
    ////            for key in addr.keys {
    ////                if let privK = ArmorUnarmor(key.private_key, &error) {
    ////                    out.append(privK)
    ////                }
    ////            }
    ////        }
    ////        return out
    //        return Data()
    //    }
    
    //    var firstUserPublicKey: String? {
    //        if userKeys.count > 0 {
    //            for k in userKeys {
    //                return k.publicKey
    //            }
    //        }
    //        return nil
    //    }
    
    public func getAddressPrivKey(address_id: String) -> String {
        let addr = userAddresses.indexOfAddress(address_id) ?? userAddresses.defaultSendAddress()
        return addr?.keys.first?.private_key ?? ""
    }
    
    public func getAddressKey(address_id: String) -> Key? {
        let addr = userAddresses.indexOfAddress(address_id) ?? userAddresses.defaultSendAddress()
        return addr?.keys.first
    }
    
    /// Get all keys that belong to the given address id
    /// - Parameter address_id: Address id
    /// - Returns: Keys of the given address id. nil means can't find the address
    public func getAllAddressKey(address_id: String) -> [Key]? {
        guard let addr = userAddresses.indexOfAddress(address_id) else {
            return nil
        }
        return addr.keys
    }
}

extension UserInfo {
    /// Initializes the UserInfo with the response data
    public convenience init(response: [String: Any]) {
        var uKeys: [Key] = [Key]()
        if let user_keys = response["Keys"] as? [[String: Any]] {
            for key_res in user_keys {
                uKeys.append(Key(
                                key_id: key_res["ID"] as? String,
                                private_key: key_res["PrivateKey"] as? String,
                                token: key_res["Token"] as? String,
                                signature: key_res["Signature"] as? String,
                                activation: key_res["Activation"] as? String,
                                isupdated: false))
            }
        }
        let userId = response["ID"] as? String
        let usedS = response["UsedSpace"] as? NSNumber
        let maxS = response["MaxSpace"] as? NSNumber
        let credit = response["Credit"] as? NSNumber
        let currency = response["Currency"] as? String
        let subscribed = response["Subscribed"] as? Int
        self.init(
            maxSpace: maxS?.int64Value,
            usedSpace: usedS?.int64Value,
            language: response["Language"] as? String,
            maxUpload: response["MaxUpload"] as? Int64,
            role: response["Role"] as? Int,
            delinquent: response["Delinquent"] as? Int,
            keys: uKeys,
            userId: userId,
            linkConfirmation: response["ConfirmLink"] as? Int,
            credit: credit?.intValue,
            currency: currency,
            subscribed: subscribed
        )
    }
}

// MARK: - NSCoding
extension UserInfo: NSCoding {
    
    fileprivate struct CoderKey {
        static let displayName = "displayName"
        static let maxSpace = "maxSpace"
        static let notificationEmail = "notificationEmail"
        static let signature = "signature"
        static let usedSpace = "usedSpace"
        static let userStatus = "userStatus"
        static let userAddress = "userAddresses"
        
        static let autoSaveContact = "autoSaveContact"
        static let language = "language"
        static let maxUpload = "maxUpload"
        static let notify = "notify"
        static let showImages = "showImages"
        
        static let swipeLeft = "swipeLeft"
        static let swipeRight = "swipeRight"
        
        static let role = "role"
        
        static let delinquent = "delinquent"
        
        static let userKeys = "userKeys"
        static let userId = "userId"
        
        static let attachPublicKey = "attachPublicKey"
        static let sign = "sign"
        
        static let linkConfirmation = "linkConfirmation"
        
        static let credit = "credit"
        static let currency = "currency"
        static let subscribed = "subscribed"
        
        static let pwdMode = "passwordMode"
        static let twoFA = "2faStatus"
        
        static let enableFolderColor = "enableFolderColor"
        static let inheritParentFolderColor = "inheritParentFolderColor"
    }
    
    public func archive() -> Data {
        return try! NSKeyedArchiver.archivedData(withRootObject: self, requiringSecureCoding: false)
    }
    
    static public func unarchive(_ data: Data?) -> UserInfo? {
        guard let data = data else { return nil }
        
        return try? NSKeyedUnarchiver.unarchivedObject(ofClass: UserInfo.self, from: data)
    }
    
    public convenience init(coder aDecoder: NSCoder) {
        self.init(
            displayName: aDecoder.decodeStringForKey(CoderKey.displayName),
            maxSpace: aDecoder.decodeInt64(forKey: CoderKey.maxSpace),
            notificationEmail: aDecoder.decodeStringForKey(CoderKey.notificationEmail),
            signature: aDecoder.decodeStringForKey(CoderKey.signature),
            usedSpace: aDecoder.decodeInt64(forKey: CoderKey.usedSpace),
            userAddresses: aDecoder.decodeObject(forKey: CoderKey.userAddress) as? [Address],
            
            autoSC: aDecoder.decodeInteger(forKey: CoderKey.autoSaveContact),
            language: aDecoder.decodeStringForKey(CoderKey.language),
            maxUpload: aDecoder.decodeInt64(forKey: CoderKey.maxUpload),
            notify: aDecoder.decodeInteger(forKey: CoderKey.notify),
            showImage: aDecoder.decodeInteger(forKey: CoderKey.showImages),
            
            swipeL: aDecoder.decodeInteger(forKey: CoderKey.swipeLeft),
            swipeR: aDecoder.decodeInteger(forKey: CoderKey.swipeRight),
            
            role: aDecoder.decodeInteger(forKey: CoderKey.role),
            
            delinquent: aDecoder.decodeInteger(forKey: CoderKey.delinquent),
            
            keys: aDecoder.decodeObject(forKey: CoderKey.userKeys) as? [Key],
            userId: aDecoder.decodeStringForKey(CoderKey.userId),
            sign: aDecoder.decodeInteger(forKey: CoderKey.sign),
            attachPublicKey: aDecoder.decodeInteger(forKey: CoderKey.attachPublicKey),
            
            linkConfirmation: aDecoder.decodeStringForKey(CoderKey.linkConfirmation),
            
            credit: aDecoder.decodeInteger(forKey: CoderKey.credit),
            currency: aDecoder.decodeStringForKey(CoderKey.currency),
            
            pwdMode: aDecoder.decodeInteger(forKey: CoderKey.pwdMode),
            twoFA: aDecoder.decodeInteger(forKey: CoderKey.twoFA),
            enableFolderColor: aDecoder.decodeInteger(forKey: CoderKey.enableFolderColor),
            inheritParentFolderColor: aDecoder.decodeInteger(forKey: CoderKey.inheritParentFolderColor),
            subscribed: aDecoder.decodeInteger(forKey: CoderKey.subscribed)
        )
    }
    
    public func encode(with aCoder: NSCoder) {
        aCoder.encode(maxSpace, forKey: CoderKey.maxSpace)
        aCoder.encode(notificationEmail, forKey: CoderKey.notificationEmail)
        aCoder.encode(usedSpace, forKey: CoderKey.usedSpace)
        aCoder.encode(userAddresses, forKey: CoderKey.userAddress)
        
        aCoder.encode(language, forKey: CoderKey.language)
        aCoder.encode(maxUpload, forKey: CoderKey.maxUpload)
        aCoder.encode(notify, forKey: CoderKey.notify)
        
        aCoder.encode(role, forKey: CoderKey.role)
        aCoder.encode(delinquent, forKey: CoderKey.delinquent)
        aCoder.encode(userKeys, forKey: CoderKey.userKeys)
        
        // get from mail settings
        aCoder.encode(displayName, forKey: CoderKey.displayName)
        aCoder.encode(defaultSignature, forKey: CoderKey.signature)
        aCoder.encode(autoSaveContact, forKey: CoderKey.autoSaveContact)
        aCoder.encode(showImages.rawValue, forKey: CoderKey.showImages)
        aCoder.encode(swipeLeft, forKey: CoderKey.swipeLeft)
        aCoder.encode(swipeRight, forKey: CoderKey.swipeRight)
        aCoder.encode(userId, forKey: CoderKey.userId)
        aCoder.encode(enableFolderColor, forKey: CoderKey.enableFolderColor)
        aCoder.encode(inheritParentFolderColor, forKey: CoderKey.inheritParentFolderColor)
        
        aCoder.encode(sign, forKey: CoderKey.sign)
        aCoder.encode(attachPublicKey, forKey: CoderKey.attachPublicKey)
        
        aCoder.encode(linkConfirmation.rawValue, forKey: CoderKey.linkConfirmation)
        
        aCoder.encode(credit, forKey: CoderKey.credit)
        aCoder.encode(currency, forKey: CoderKey.currency)
        aCoder.encode(subscribed, forKey: CoderKey.subscribed)
        
        aCoder.encode(passwordMode, forKey: CoderKey.pwdMode)
        aCoder.encode(twoFactor, forKey: CoderKey.twoFA)
    }
}

public extension UserInfo {
    
    var userPrivateKeys : Data {
        var out = Data()
        var error : NSError?
        for key in userKeys {
            if let privK = ArmorUnarmor(key.private_key, &error) {
                out.append(privK)
            }
        }
        return out
    }
    
    var userPrivateKeysArray: [Data] {
        var out: [Data] = []
        var error: NSError?
        for key in userKeys {
            if let privK = ArmorUnarmor(key.private_key, &error) {
                out.append(privK)
            }
        }
        return out
    }
    
}
