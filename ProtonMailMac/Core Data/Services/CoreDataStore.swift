//
//  CoreDataStore.swift
//  ProtonMailMac
//
//  Created by Marcel Piešťanský on 29.08.2021.
//  Copyright © 2021 marpies. All rights reserved.
//

import Foundation
import CoreData

class CoreDataStore {
    
    static let name: String = "ProtonMail.sqlite"
    
    class var dbUrl: URL {
        let url = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        
        if !FileManager.default.fileExists(atPath: url.path) {
            do {
                try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
            } catch let ex as NSError {
                PMLog.D("Could not create \(url.path) with error: \(ex)")
            }
        }
        
        return url.appendingPathComponent("ProtonMail.sqlite")
    }
    
    private lazy var managedObjectModel: NSManagedObjectModel = { [unowned self] in
        var modelURL = Bundle.main.url(forResource: "ProtonMail", withExtension: "momd")!
        return NSManagedObjectModel(contentsOf: modelURL)!
    }()
    
    public lazy var defaultContainer: NSPersistentContainer = { [unowned self] in
        return self.newPersistentContainer(self.managedObjectModel, name: CoreDataStore.name, url: CoreDataStore.dbUrl)
    }()
    
    private func newPersistentContainer(_ managedObjectModel: NSManagedObjectModel, name: String, url: URL) -> NSPersistentContainer {
        var url = url
        let container = NSPersistentContainer(name: name, managedObjectModel: managedObjectModel)
        
        let description = NSPersistentStoreDescription(url: url)
        description.shouldMigrateStoreAutomatically = true
        description.shouldInferMappingModelAutomatically = true
        
        container.persistentStoreDescriptions = [description]
        container.loadPersistentStores { (persistentStoreDescription, error) in
            if let ex = error as NSError? {
                PMLog.D(api: ex)
                
                container.loadPersistentStores { (persistentStoreDescription, error) in
                    if let ex = error as NSError? {
                        PMLog.D(api: ex)
                        
                        do {
                            try FileManager.default.removeItem(at: url)
                            // todo LastUpdatedStore.clear()
                        } catch let error as NSError{
                            self.popError(error)
                        }
                        
                        self.popError(ex)
                        fatalError()
                    }
                }
            } else {
                url.excludeFromBackup()
                container.viewContext.automaticallyMergesChangesFromParent = true
                container.viewContext.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
            }
        }
        return container
    }
    
    func popError (_ error : NSError) {
        // Report any error we got.
        var dict = [AnyHashable: Any]()
        dict[NSLocalizedDescriptionKey] = "Failed to initialize the app's saved data"//LocalString._error_core_data_save_failed
        dict[NSLocalizedFailureReasonErrorKey] = "There was an error creating or loading the app's saved data."//LocalString._error_core_data_load_failed
        dict[NSUnderlyingErrorKey] = error
        //TODO:: need monitor
        let CoreDataServiceErrorDomain = NSError.protonMailErrorDomain("CoreDataService")
        let _ = NSError(domain: CoreDataServiceErrorDomain, code: 9999, userInfo: dict as [AnyHashable: Any] as? [String : Any])
        
        assert(false, "Unresolved error \(error), \(error.userInfo)")
        PMLog.D("Unresolved error \(error), \(error.userInfo)")
        
        //TODO::Fix should use delegate let windown to know
        //let alertController = alertError.alertController()
        //alertController.addAction(UIAlertAction(title: LocalString._general_close_action, style: .default, handler: { (action) -> Void in
        //abort()
        //}))
        //UIApplication.shared.keyWindow?.rootViewController?.present(alertController, animated: true, completion: nil)
    }
    
}
