//
//  ConversationDiffing.swift
//  ProtonMailMac
//
//  Created by Marcel Piešťanský on 16.09.2021.
//  Copyright © 2021 marpies. All rights reserved.
//

import Foundation

protocol ConversationDiffing {
    func getConversationsDiff(oldConversations: [Conversations.Conversation.Response], newConversations: [Conversations.Conversation.Response], updatedConversationIds: Set<String>?) -> Conversations.UpdateConversations.Response
}

extension ConversationDiffing {
    
    func getConversationsDiff(oldConversations: [Conversations.Conversation.Response], newConversations: [Conversations.Conversation.Response], updatedConversationIds: Set<String>?) -> Conversations.UpdateConversations.Response {
        var removeSet: IndexSet?
        var insertSet: IndexSet?
        var updateSet: IndexSet?
        
        if !oldConversations.isEmpty {
            let oldIds: Set<String> = self.getConversationIds(oldConversations)
            let newIds: Set<String> = self.getConversationIds(newConversations)
            let removedIds: Set<String> = oldIds.subtracting(newIds)
            let insertedIds: Set<String> = newIds.subtracting(oldIds)
            
            if !removedIds.isEmpty {
                removeSet = self.getIndexSet(ids: removedIds, conversations: oldConversations)
            }
            
            if !insertedIds.isEmpty {
                insertSet = self.getIndexSet(ids: insertedIds, conversations: newConversations)
            }
            
            if let ids = updatedConversationIds {
                updateSet = self.getIndexSet(ids: ids, conversations: newConversations)
            }
            
            // Compare hashes of old and new conversations
            for (index, newConv) in newConversations.enumerated() {
                guard let oldConv = oldConversations.first(where: { $0.id == newConv.id }) else { continue }
                
                if oldConv != newConv {
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
        
        return Conversations.UpdateConversations.Response(conversations: newConversations, removeSet: removeSet, insertSet: insertSet, updateSet: updateSet)
    }
    
    //
    // MARK: - Private
    //
    
    private func getConversationIds(_ conversations: [Conversations.Conversation.Response]) -> Set<String> {
        var ids: Set<String> = []
        conversations.forEach { ids.insert($0.id) }
        return ids
    }
    
    private func getIndexSet(ids: Set<String>, conversations: [Conversations.Conversation.Response]) -> IndexSet {
        var indices: [Int] = []
        
        for id in ids {
            guard let index = conversations.firstIndex(where: { $0.id == id }) else { continue }
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
