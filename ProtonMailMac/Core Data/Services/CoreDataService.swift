//
//  CoreDataService.swift
//  ProtonMailMac
//
//  Created by Marcel Piešťanský on 29.08.2021.
//  Copyright © 2021 marpies. All rights reserved.
//

import Foundation
import CoreData

class CoreDataService {
    
    private let serialQueue: OperationQueue = {
        let persistentContainerQueue = OperationQueue()
        persistentContainerQueue.maxConcurrentOperationCount = 1
        return persistentContainerQueue
    }()
    
    let container: NSPersistentContainer
    
    lazy var mainContext: NSManagedObjectContext = {
        return self.container.viewContext
    }()
    
    lazy var backgroundContext: NSManagedObjectContext = {
        let ctx: NSManagedObjectContext = self.container.newBackgroundContext()
        ctx.automaticallyMergesChangesFromParent = true
        ctx.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
        return ctx
    }()
    
    init(container: NSPersistentContainer) {
        self.container = container
    }
    
}