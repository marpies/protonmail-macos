//
//  Label+Defaults.swift
//  ProtonMailMac
//
//  Created by Marcel Piešťanský on 07.09.2021.
//  Copyright © 2021 marpies. All rights reserved.
//

import Foundation

extension Label {
    
    override public func awakeFromInsert() {
        super.awakeFromInsert()
        
        replaceNilStringAttributesWithEmptyString()
    }
    
}
