//
//  NotificationType.swift
//  ProtonMailMac
//
//  Created by Marcel Piešťanský on 22.09.2021.
//  Copyright © 2021 marpies. All rights reserved.
//

import Foundation

public protocol NotificationType {
    static var name: Notification.Name { get }
    
    var name: Notification.Name { get }
    
    var userInfo: [AnyHashable : Any]? { get }
    
    init?(notification: Notification?)
    
    /// Posts the notification using the default notification center.
    func post()
}

public extension NotificationType {
    
    func post() {
        NotificationCenter.default.post(self)
    }
    
}

public extension NotificationCenter {
    
    func post(_ notification: NotificationType, object: Any? = nil) {
        self.post(name: notification.name, object: object, userInfo: notification.userInfo)
    }
    
    func addObserver<T: NotificationType>(forType type: T.Type, object obj: Any? = nil, queue: OperationQueue? = nil,
                                          using block: @escaping (T?) -> Swift.Void) -> NSObjectProtocol {
        return self.addObserver(forName: type.name, object: obj, queue: queue) {
            block( type.init(notification: $0) )
        }
    }
    
    func removeObserver(optional observer: NSObjectProtocol?) {
        if let observer = observer {
            self.removeObserver(observer)
        }
    }
    
}
