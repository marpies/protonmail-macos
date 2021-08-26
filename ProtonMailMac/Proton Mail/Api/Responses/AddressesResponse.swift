//
//  File.swift
//  
//
//  Created by Marcel Piešťanský on 22.08.2021.
//

import Foundation

public final class AddressesResponse : Response {
    public private(set) var addresses: [Address] = [Address]()

    override public func parseResponse(_ response: [String : Any]) -> Bool {
        if let addresses = response["Addresses"] as? [[String : Any]] {
            for address in addresses {
                self.parseAddr(res: address)
            }
        } else if let address = response["Address"] as? [String : Any] {
            self.parseAddr(res: address)
        }
        return true
    }
    
    func parseAddr(res: [String : Any]!) {
        var keys: [Key] = [Key]()
        if let address_keys = res["Keys"] as? [[String : Any]] {
            for key_res in address_keys {
                keys.append(Key(
                                key_id: key_res["ID"] as? String,
                                private_key: key_res["PrivateKey"] as? String,
                                token: key_res["Token"] as? String,
                                signature: key_res["Signature"] as? String,
                                activation: key_res["Activation"] as? String,
                                isupdated: false))
            }
        }
        
        self.addresses.append(Address(
            addressid: res["ID"] as? String,
            email:res["Email"] as? String,
            order: res["Order"] as? Int,
            receive: res["Receive"] as? Int,
            display_name: res["DisplayName"] as? String,
            signature: res["Signature"] as? String,
            keys : keys,
            status: res["Status"] as? Int,
            type: res["Type"] as? Int,
            send: res["Send"] as? Int
        ))
    }
}
