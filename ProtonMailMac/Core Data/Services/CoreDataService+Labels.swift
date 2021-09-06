//
//  CoreDataService+Labels.swift
//  ProtonMailMac
//
//  Created by Marcel Piešťanský on 29.08.2021.
//  Copyright © 2021 marpies. All rights reserved.
//

import Foundation
import CoreData

extension CoreDataService: LabelsDatabaseManaging {
    
    func saveLabels(_ json: [[String : Any]], forUser userId: String, completion: @escaping () -> Void) {
        self.backgroundContext.performWith { ctx in
            for labelJson in json {
                guard let id = labelJson.getString("ID") else { continue }
                
                let label = Label(context: ctx)
                label.labelID = id
                label.userID = userId
                label.name = labelJson.getString("Name") ?? ""
                label.color = labelJson.getString("Color") ?? ""
                label.exclusive = labelJson.getBool("Exclusive") ?? true
                label.parentID = labelJson.getString("ParentID") ?? ""
                label.isDisplay = true
                label.order = NSNumber(integerLiteral: labelJson.getInt("Order") ?? label.defaultOrder)
                label.type = NSNumber(integerLiteral: labelJson.getInt("Type") ?? 0)
            }
            
            if let error = ctx.saveUpstreamIfNeeded() {
                PMLog.D("Error saving Labels \(error)")
            } else {
                PMLog.D("Success saving labels")
            }
            
            DispatchQueue.main.async {
                completion()
            }
        }
    }
    
    func fetchLabels(ofType type: LabelFetchType, forUser userId: String, completion: @escaping ([Label]) -> Void) {
        self.backgroundContext.performWith { ctx in
            let labels = self.fetchLabels(ofType: type, forUser: userId, withContext: ctx)
            
            DispatchQueue.main.async {
                completion(labels)
            }
        }
    }
    
    func fetchLabels(ofType type: LabelFetchType, forUser userId: String, withContext context: NSManagedObjectContext) -> [Label] {
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Label")
        request.predicate = self.getPredicate(type, userId: userId)
        request.sortDescriptors = [NSSortDescriptor(key: "order", ascending: true)]
        
        do {
            if let labels = try context.fetch(request) as? [Label] {
                return labels
            }
        } catch {
            PMLog.D("Error fetching labels \(error)")
        }
        
        return []
    }
    
    //
    // MARK: - Private
    //
    
    private func getPredicate(_ type: LabelFetchType, userId: String) -> NSPredicate {
        switch type {
        case .all:
            let defaults = NSPredicate(format: "labelID IN %@", [0, 1, 2, 3, 4, 5, 6, 10])
            let user = NSPredicate(format: "(labelID MATCHES %@) AND (type == 1) AND (userID == %@)", "(?!^\\d+$)^.+$", userId)
            return NSCompoundPredicate(orPredicateWithSubpredicates: [defaults, user])
        case .folder:
            return NSPredicate(format: "(labelID MATCHES %@) AND (type == 1) AND (exclusive == true) AND (userID == %@)", "(?!^\\d+$)^.+$", userId)
        case .folderWithInbox:
            // 0 - inbox, 6 - archive, 3 - trash, 4 - spam
            let defaults = NSPredicate(format: "labelID IN %@", [0, 6, 3, 4])
            // custom folders like in previous (LabelFetchType.folder) case
            let folder = NSPredicate(format: "(labelID MATCHES %@) AND (type == 1) AND (exclusive == true) AND (userID == %@)", "(?!^\\d+$)^.+$", userId)
            
            return NSCompoundPredicate(orPredicateWithSubpredicates: [defaults, folder])
        case .folderWithOutbox:
            // 7 - sent, 6 - archive, 3 - trash
            let defaults = NSPredicate(format: "labelID IN %@", [6, 7, 3])
            // custom folders like in previous (LabelFetchType.folder) case
            let folder = NSPredicate(format: "(labelID MATCHES %@) AND (type == 1) AND (exclusive == true) AND (userID == %@)", "(?!^\\d+$)^.+$", userId)
            
            return NSCompoundPredicate(orPredicateWithSubpredicates: [defaults, folder])
        case .label:
            return NSPredicate(format: "(labelID MATCHES %@) AND (type == 1) AND (exclusive == false) AND (userID == %@)", "(?!^\\d+$)^.+$", userId)
        case .contactGroup:
            return NSPredicate(format: "(type == 2) AND (userID == %@)", userId)
        }
    }
    
}
