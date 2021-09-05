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
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Label")
        request.predicate = self.getPredicate(type)
        request.sortDescriptors = [NSSortDescriptor(key: "order", ascending: true)]
        
        self.backgroundContext.performWith { ctx in
            do {
                if let labels = try ctx.fetch(request) as? [Label] {
                    DispatchQueue.main.async {
                        completion(labels)
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    completion([])
                }
            }
        }
    }
    
    //
    // MARK: - Private
    //
    
    private func getPredicate(_ type: LabelFetchType) -> NSPredicate {
        switch type {
        case .all:
            let defaults = NSPredicate(format: "labelID IN %@", [0, 1, 2, 3, 4, 5, 6, 10])
            let user = NSPredicate(format: "(labelID MATCHES %@) AND (type == 1) AND (userID == %@)", "(?!^\\d+$)^.+$")
            return NSCompoundPredicate(orPredicateWithSubpredicates: [defaults, user])
        case .folder:
            return NSPredicate(format: "(labelID MATCHES %@) AND (type == 1) AND (exclusive == true) AND (userID == %@)", "(?!^\\d+$)^.+$")
        case .folderWithInbox:
            // 0 - inbox, 6 - archive, 3 - trash, 4 - spam
            let defaults = NSPredicate(format: "labelID IN %@", [0, 6, 3, 4])
            // custom folders like in previous (LabelFetchType.folder) case
            let folder = NSPredicate(format: "(labelID MATCHES %@) AND (type == 1) AND (exclusive == true) AND (userID == %@)", "(?!^\\d+$)^.+$")
            
            return NSCompoundPredicate(orPredicateWithSubpredicates: [defaults, folder])
        case .folderWithOutbox:
            // 7 - sent, 6 - archive, 3 - trash
            let defaults = NSPredicate(format: "labelID IN %@", [6, 7, 3])
            // custom folders like in previous (LabelFetchType.folder) case
            let folder = NSPredicate(format: "(labelID MATCHES %@) AND (type == 1) AND (exclusive == true) AND (userID == %@)", "(?!^\\d+$)^.+$")
            
            return NSCompoundPredicate(orPredicateWithSubpredicates: [defaults, folder])
        case .label:
            return NSPredicate(format: "(labelID MATCHES %@) AND (type == 1) AND (exclusive == false) AND (userID == %@)", "(?!^\\d+$)^.+$")
        case .contactGroup:
            return NSPredicate(format: "(type == 2) AND (userID == %@)")
        }
    }
    
}
