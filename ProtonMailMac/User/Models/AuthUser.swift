//
//  AuthUser.swift
//  ProtonMailMac
//
//  Created by Marcel Piešťanský on 23.08.2021.
//

import Foundation

public protocol AuthUserDelegate: AnyObject {
    func userAuthDidUpdate(_ user: AuthUser)
}

public class AuthUser: Hashable, UserDataServiceDelegate {
    
    public let userInfo: UserInfo
    public let auth: AuthCredential
    
    public lazy var userService: UserDataService = {
        let service: UserDataService = UserDataService(auth: self.auth)
        service.delegate = self
        return service
    }()
    
    public weak var delegate: AuthUserDelegate?
    
    public var userId: String {
        return self.userInfo.userId
    }
    
    public var sessionId: String {
        return self.auth.sessionID
    }

    public init(userInfo: UserInfo, auth: AuthCredential) {
        self.userInfo = userInfo
        self.auth = auth
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.userId)
    }
    
    public static func == (lhs: AuthUser, rhs: AuthUser) -> Bool {
        return lhs.userId == rhs.userId
    }
    
    //
    // MARK: - User data service delegate
    //
    
    public func authDidUpdate() {
        self.delegate?.userAuthDidUpdate(self)
    }
    
    
}
