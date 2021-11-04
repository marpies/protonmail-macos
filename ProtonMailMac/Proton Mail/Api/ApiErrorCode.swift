//
//  APIErrorCode.swift
//  
//
//  Created by Marcel Piešťanský on 22.08.2021.
//

import Foundation

public class APIErrorCode {
    static public let responseOK = 1000
    
    static public let HTTP503 = 503
    static public let HTTP504 = 504
    static public let HTTP404 = 404
    
    static public let badParameter = 1
    static public let badPath = 2
    static public let unableToParseResponse = 3
    static public let badResponse = 4
    
    public struct AuthErrorCode {
        static public let credentialExpired = 10
        static public let credentialInvalid = 20
        static public let invalidGrant = 30
        static public let unableToParseToken = 40
        static public let localCacheBad = 50
        static public let networkIusse = -1004
        static public let unableToParseAuthInfo = 70
        static public let authServerSRPInValid = 80
        static public let authUnableToGenerateSRP = 90
        static public let authUnableToGeneratePwd = 100
        static public let authInValidKeySalt = 110
        static public let loginCredentialsInvalid = 8002
        
        static public let authCacheLocked = 665
        
        static public let Cache_PasswordEmpty = 0x10000001
    }
    
    static public let API_offline = 7001
    
    public struct UserErrorCode {
        static public let userNameExsit = 12011
        static public let currentWrong = 12021
        static public let newNotMatch = 12022
        static public let pwdUpdateFailed = 12023
        static public let pwdEmpty = 12024
    }
    
    static public let badAppVersion = 5003
    static public let badApiVersion = 5005
    static public let humanVerificationRequired = 9001
    static public let invalidVerificationCode = 12087
    static public let tooManyVerificationCodes = 12214
    static public let tooManyFailedVerificationAttempts = 85131
}
