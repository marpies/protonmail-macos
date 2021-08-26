//
//  File.swift
//  
//
//  Created by Marcel Piešťanský on 22.08.2021.
//

import Foundation

public final class UserInfoResponse: Response {
    public private(set) var userInfo: UserInfo?
    
    override public func parseResponse(_ response: [String: Any]) -> Bool {
        guard let res = response["User"] as? [String: Any] else {
            return false
        }
        self.userInfo = UserInfo(response: res)
        return true
    }
}
