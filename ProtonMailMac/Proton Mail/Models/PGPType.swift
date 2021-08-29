//
//  PGPType.swift
//  ProtonMailMac
//
//  Created by Marcel Piešťanský on 29.08.2021.
//  Copyright © 2021 marpies. All rights reserved.
//

import Foundation

enum PGPType : Int {
    //Do not use -1, this value will break the locker check function
    case failed_validation = -3 // not pass FE validation
    case failed_server_validation = -2 // not pass BE validation
    case none = 0 /// default none
    case pgp_signed = 1 /// external pgp signed only
    case pgp_encrypt_trusted_key = 2 /// external encrypted and signed with trusted key
    case internal_normal = 3 /// protonmail normal keys
    case internal_trusted_key = 4  /// trusted key
    case pgp_encrypt_trusted_key_verify_failed = 6
    case internal_trusted_key_verify_failed = 7
    case internal_normal_verify_failed = 8
    case pgp_signed_verify_failed = 9
    case eo = 10
    case pgp_encrypted = 11
    case sent_sender_out_side = 12
    case sent_sender_encrypted = 13
    case zero_access_store = 14
    case sent_sender_server = 15
    case pgp_signed_verified = 16
}
