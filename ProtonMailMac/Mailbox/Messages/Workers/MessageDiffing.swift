//
//  MessageDiffing.swift
//  ProtonMailMac
//
//  Created by Marcel Piešťanský on 09.09.2021.
//  Copyright © 2021 marpies. All rights reserved.
//

import Foundation

protocol MessageDiffing {
    func getMessagesDiff(oldMessages: [Messages.Message.Response], newMessages: [Messages.Message.Response], updatedMessageIds: Set<String>?) -> Messages.UpdateMessages.Response?
}

extension MessageDiffing {
    
    func getMessagesDiff(oldMessages: [Messages.Message.Response], newMessages: [Messages.Message.Response], updatedMessageIds: Set<String>?) -> Messages.UpdateMessages.Response? {
        var removeSet: IndexSet?
        var insertSet: IndexSet?
        var updateSet: IndexSet?
        
        if !oldMessages.isEmpty {
            let oldIds: Set<String> = self.getMessageIds(oldMessages)
            let newIds: Set<String> = self.getMessageIds(newMessages)
            let removedIds: Set<String> = oldIds.subtracting(newIds)
            let insertedIds: Set<String> = newIds.subtracting(oldIds)
            
            if !removedIds.isEmpty {
                removeSet = self.getIndexSet(ids: removedIds, messages: oldMessages)
            }
            
            if !insertedIds.isEmpty {
                insertSet = self.getIndexSet(ids: insertedIds, messages: newMessages)
            }
            
            if let ids = updatedMessageIds {
                updateSet = self.getIndexSet(ids: ids, messages: newMessages)
            }
            
            // Compare hashes of old and new messages
            for (index, newMsg) in newMessages.enumerated() {
                guard let oldMsg = oldMessages.first(where: { $0.id == newMsg.id }) else { continue }
                
                if oldMsg != newMsg {
                    updateSet = updateSet ?? IndexSet()
                    updateSet?.insert(index)
                }
            }
            
            // Just in case, remove indices from "updateSet" if they are in "removeSet" and "insertSet"
            if updateSet != nil {
                self.removeIndices(from: &updateSet!, in: removeSet)
                self.removeIndices(from: &updateSet!, in: insertSet)
            }
        }
        
        if updateSet == nil && insertSet == nil && removeSet == nil {
            return nil
        }
        
        return Messages.UpdateMessages.Response(messages: newMessages, removeSet: removeSet, insertSet: insertSet, updateSet: updateSet)
    }
    
    //
    // MARK: - Private
    //
    
    private func getMessageIds(_ messages: [Messages.Message.Response]) -> Set<String> {
        var ids: Set<String> = []
        messages.forEach { ids.insert($0.id) }
        return ids
    }
    
    private func getIndexSet(ids: Set<String>, messages: [Messages.Message.Response]) -> IndexSet {
        var indices: [Int] = []
        
        for id in ids {
            guard let index = messages.firstIndex(where: { $0.id == id }) else { continue }
            indices.append(index)
        }
        
        indices.sort(by: <)
        
        return IndexSet(indices)
    }
    
    private func removeIndices(from set1: inout IndexSet, in set2: IndexSet?) {
        guard let set2 = set2 else { return }
        
        for id in set2 {
            set1.remove(id)
        }
    }
    
}
