//
//  EventLatestIDRequest.swift
//  ProtonMail - Created on 6/26/15.
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


struct EventLatestIDRequest : Request {
    
    var authCredential: AuthCredential?
    
    var path: String {
        return EventAPI.path + "/latest"
    }
    
    func copyWithCredential(_ credential: AuthCredential) -> EventLatestIDRequest {
        var copy: EventLatestIDRequest = self
        let newCredential: AuthCredential = copy.authCredential ?? credential
        newCredential.update(sessionID: credential.sessionID, accessToken: credential.accessToken, refreshToken: credential.refreshToken, expiration: credential.expiration)
        copy.authCredential = newCredential
        return copy
    }
}
