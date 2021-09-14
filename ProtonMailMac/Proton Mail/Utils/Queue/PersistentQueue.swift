//
//  PersistentQueue.swift
//  ProtonMail
//
//
//  Copyright (c) 2019 Proton Technologies AG
//
//  This file is part of ProtonMail.
//
//  ProtonMail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ProtonMail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonMail.  If not, see <https://www.gnu.org/licenses/>.


import Foundation

@objcMembers class PersistentQueue: NSObject {
    
    struct Key {
        static let elementID = "elementID"
        static let object = "object"
    }
    
    fileprivate var queueURL: URL
    fileprivate let queueName: String
    
    internal var mutex = UnsafeMutablePointer<pthread_mutex_t>.allocate(capacity: 1)
    
    dynamic fileprivate(set) var queue: [[String: Any]] {
        didSet {
            DispatchQueue.global(qos: .background).sync { () -> Void in
                do {
                    let data = try NSKeyedArchiver.archivedData(withRootObject: self.queue, requiringSecureCoding: false)
                    try data.write(to: self.queueURL, options: [.atomic])
                    self.queueURL.excludeFromBackup()
                } catch {
                    PMLog.D("Unable to save queue: \(self.queue as NSArray)\n to \(self.queueURL.absoluteString)")
                }
            }
        }
    }
    
    /// Number of objects in the Queue
    var count: Int {
        return self.queue.count
    }
    
    func queueArray() -> [Any] {
        return self.queue
    }
    
    init(queueName: String) {
        self.queueName = "\(QueueConstant.queueIdentifer).\(queueName)"
        
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        self.queueURL = dir.appendingPathComponent(self.queueName)
        
        if let data = try? Data(contentsOf: queueURL),
           let queueAny = try? NSKeyedUnarchiver.unarchivedObject(ofClass: NSArray.self, from: data),
           let queue = queueAny as? [[String: Any]] {
            self.queue = queue
        }
        else {
            self.queue = []
        }
        
        mutex.initialize(to: pthread_mutex_t())
        pthread_mutex_init(mutex, nil)
        super.init()
    }
    
    func add (_ uuid: UUID, object: NSCoding) -> UUID {
        pthread_mutex_lock(self.mutex)
        defer {
            pthread_mutex_unlock(self.mutex)
        }
        let element = [Key.elementID : uuid, Key.object : object] as [String : Any]
        self.queue.append(element)
        return uuid
    }
    
    /// Adds an object to the persistent queue.
    func add(_ object: NSCoding) -> UUID {
        let uuid = UUID()
        return self.add(uuid, object: object)
    }
    
    /// Clears the persistent queue.
    func clear() {
        queue.removeAll()
    }
    
    /// Returns the next item in the persistent queue or nil, if the queue is empty.
    func next() -> (elementID: UUID, object: Any)? {
        if let element = queue.first {
            return (element[Key.elementID] as! UUID, element[Key.object]!)
        }
        return nil
    }
    
    /// Removes an element from the persistent queue
    func remove(_ elementID: UUID) -> Bool {
        pthread_mutex_lock(self.mutex)
        defer {
            pthread_mutex_unlock(self.mutex)
        }
        for (index, element) in queue.enumerated() {
            if let kID = element[Key.elementID] as? UUID{
                if kID == elementID {
                    queue.remove(at: index)
                    return true
                }
            }
        }
        return false
    }
    
    
    func removeDuplicated(_ messageID: String, key: String, actionKey: String, actions : [String]) {
        pthread_mutex_lock(self.mutex)
        defer {
            pthread_mutex_unlock(self.mutex)
        }
        self.queue.removeAll { (element) -> Bool in
            if let object = element[Key.object] as? [String : Any],
               let msgID = object[key] as? String,
               let action = object[actionKey] as? String,
               messageID == msgID,
               actions.contains(action) {
                return true
            }
            return false
        }
    }
    
    func remove<T>(key: String, value: T) where T: Equatable {
        pthread_mutex_lock(self.mutex)
        defer {
            pthread_mutex_unlock(self.mutex)
        }
        self.queue.removeAll { (element) -> Bool in
            if let object = element[Key.object] as? [String : Any],
               let found = object[key] as? T,
               found == value {
                return true
            }
            return false
        }
    }
}
