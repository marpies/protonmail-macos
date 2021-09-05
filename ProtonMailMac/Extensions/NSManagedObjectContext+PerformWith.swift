//
//  NSManagedObjectContext+Extensions.swift
//  ProtonMailMac
//
//  Created by Marcel Piešťanský on 05.09.2021.
//  Copyright © 2021 marpies. All rights reserved.
//

import Foundation
import CoreData

extension NSManagedObjectContext {
    
    func performWith(block: @escaping (NSManagedObjectContext) -> Void) {
        self.perform {
            block(self)
        }
    }
    
    func performAndWaitWith(block: @escaping (NSManagedObjectContext) -> Void) {
        self.performAndWait {
            block(self)
        }
    }
    
}
