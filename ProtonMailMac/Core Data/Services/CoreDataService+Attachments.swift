//
//  CoreDataService+Attachments.swift
//  ProtonMailMac
//
//  Created by Marcel Piešťanský on 25.09.2021.
//  Copyright © 2021 marpies. All rights reserved.
//

import Foundation
import CoreData

extension CoreDataService: AttachmentsDatabaseManaging {
    
    func update(attachment: Attachment, fileUrl: URL, completion: @escaping (NSError?) -> Void) {
        if let ctx = attachment.managedObjectContext {
            ctx.perform {
                var error: NSError?
                
                attachment.localURL = fileUrl
                
                do {
                    attachment.fileData = try Data(contentsOf: fileUrl)
                    error = ctx.saveUpstreamIfNeeded()
                } catch let e as NSError {
                    error = e
                }
                
                if let e = error {
                    PMLog.D("Error updating attachment: \(e)")
                }
                
                DispatchQueue.main.async {
                    completion(error)
                }
            }
        } else {
            completion(NSError.unknownError())
        }
    }
    
}
