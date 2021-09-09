//
//  UsersManager.swift
//  ProtonMailMac
//
//  Created by Marcel Piešťanský on 23.08.2021.
//

import Foundation
import PMKeymaker

class UsersManager: AuthUserDelegate {
    
    private let keymaker: KeymakerWrapper
    private let keyValueStore: KeyValueStore
    
    private(set) var users: [AuthUser] = [] {
        didSet {
            if let sessionId = self.users.first?.auth.sessionID,
               let mainKey = self.keymaker.mainKey,
               let encrypted = try? Locked<String>(clearValue: sessionId, with: mainKey) {
                self.keyValueStore.setData(forKey: .primaryUserSessionId, value: encrypted.encryptedValue)
            } else {
                self.keyValueStore.removeValue(forKey: .primaryUserSessionId)
            }
        }
    }
    
    var isLoggedIn: Bool {
        return self.keyValueStore.bool(forKey: .isLoggedIn) ?? false
    }
    
    var activeUser: AuthUser? {
        return self.users.first
    }
    
    init(keymaker: KeymakerWrapper, keyValueStore: KeyValueStore) {
        self.keymaker = keymaker
        self.keyValueStore = keyValueStore
    }
    
    func makeUserActive(uid: String) {
        if let index = self.users.enumerated().first(where: { $1.sessionId == uid })?.offset,
           index > 0 {
            self.users.swapAt(0, index)
            self.save()
        }
    }
    
    func makeUserActive(at index: Int) {
        guard !self.users.isEmpty, index < self.users.count, index != 0 else { return }
        
        self.users.swapAt(0, index)
        self.save()
    }
    
    /// Adds new user.
    func add(userInfo: UserInfo, auth: AuthCredential) {
        let newUser = AuthUser(userInfo: userInfo, auth: auth)
        newUser.delegate = self
        self.users.append(newUser)
    }
    
    func getUser(forId userId: String) -> AuthUser? {
        return self.users.first { user in
            return user.userInfo.userId == userId
        }
    }
    
    /// Attempts to restore info for previously authenticated users.
    func restore() {
        assert(self.keymaker.mainKeyExists())
        
        guard let mainKey = self.keymaker.mainKey,
              let encryptedAuthData = self.keyValueStore.data(forKey: .authData) else { return }
        
        let authlocked = Locked<[AuthCredential]>(encryptedValue: encryptedAuthData)
        let auths: [AuthCredential]
        do {
            auths = try authlocked.unlock(with: mainKey)
        } catch {
            self.keyValueStore.removeValue(forKey: .authData)
            
            #if DEBUG
            print("  failed to decrypt auth data \(error)")
            #endif
            return
        }
        
        guard let encryptedUsersData = self.keyValueStore.data(forKey: .usersInfo) else { return }
        
        let userslocked = Locked<[UserInfo]>(encryptedValue: encryptedUsersData)
        guard let userInfos = try? userslocked.unlock(with: mainKey) else {
            return
        }
        
        guard userInfos.count == auths.count else {
            return
        }
        
        //Check if the existing users is the same as the users stored on the device
        let userIds = userInfos.map { $0.userId }
        let existUserIds = users.map { $0.userInfo.userId }
        if self.users.count > 0 &&
            existUserIds.count == userIds.count &&
            existUserIds.map({ userIds.contains($0) }).filter({ $0 }).count == userIds.count {
            return
        }
        
        self.users.removeAll()
        
        for (auth, user) in zip(auths, userInfos) {
            self.add(userInfo: user, auth: auth)
        }
        
        assert(!self.users.isEmpty)
        
        self.trackLogIn()
    }
    
    func save() {
        guard let mainKey = self.keymaker.mainKey else {
            #if DEBUG
            print("   ERROR Obtaining MAIN KEY")
            #endif
            return
        }
        
        let authList = self.users.compactMap{ $0.auth }
        let userList = self.users.compactMap{ $0.userInfo }
        
        #if DEBUG
        print("  Saving \(self.users.count) user(s)")
        #endif
        
        guard let lockedAuth = try? Locked<[AuthCredential]>(clearValue: authList, with: mainKey),
              let lockedUsers = try? Locked<[UserInfo]>(clearValue: userList, with: mainKey) else {
            return
        }
        
        self.keyValueStore.setData(forKey: .authData, value: lockedAuth.encryptedValue)
        self.keyValueStore.setData(forKey: .usersInfo, value: lockedUsers.encryptedValue)
    }
    
    func signOut(userId: String) {
        guard let user = self.users.first(where: { $0.auth.sessionID == userId }) else { return }
        
        self.signOut(user: user)
    }
    
    func signOut(user: AuthUser) {
        user.userService.signOut { err in
            if err == nil {
                #if DEBUG
                print("  User signed out successfully")
                #endif
                
                self.users.removeAll(where: { $0.userId == user.userId })
                
                if self.users.isEmpty {
                    self.trackAllSignedOut()
                } else {
                    self.save()
                }
            }
        }
    }
    
    func trackLogIn() {
        self.keyValueStore.setBool(forKey: .isLoggedIn, value: true)
    }
    
    func trackAllSignedOut() {
        #if DEBUG
        print("      All signed out, clearing local cache")
        #endif
        
        self.keyValueStore.removeValue(forKey: .isLoggedIn)
        
        self.keyValueStore.removeValue(forKey: .authData)
        self.keyValueStore.removeValue(forKey: .usersInfo)
        self.keyValueStore.removeValue(forKey: .primaryUserSessionId)
    }
    
    //
    // MARK: - Auth user delegate
    //
    
    func userAuthDidUpdate(_ user: AuthUser) {
        self.save()
    }
    
}
