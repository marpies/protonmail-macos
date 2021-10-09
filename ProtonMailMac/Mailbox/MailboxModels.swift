//
//  MailboxModels.swift
//  ProtonMailMac
//
//  Created by Marcel Piešťanský on 25.08.2021.
//  Copyright (c) 2021 marpies. All rights reserved.
//

import Foundation

enum Mailbox {
    
    enum Notifications {
        struct ConversationCountsUpdate: NotificationType {
            static var name: Notification.Name {
                return Notification.Name("Mailbox.ConversationCountsUpdate")
            }
            
            var name: Notification.Name {
                return ConversationCountsUpdate.name
            }
            
            var userInfo: [AnyHashable : Any]? {
                return ["unread": self.unread, "total": self.total, "userId": self.userId]
            }
            
            /// Item id to number of conversations.
            let unread: [String: Int]
            
            /// Item id to number of conversations.
            let total: [String: Int]
            let userId: String

            init(unread: [String: Int], total: [String: Int], userId: String) {
                self.unread = unread
                self.total = total
                self.userId = userId
            }
            
            init?(notification: Notification?) {
                guard let name = notification?.name,
                      name == ConversationCountsUpdate.name,
                      let userId = notification?.userInfo?["userId"] as? String,
                      let total = notification?.userInfo?["total"] as? [String: Int],
                      let unread = notification?.userInfo?["unread"] as? [String: Int] else { return nil }
                
                self.unread = unread
                self.total = total
                self.userId = userId
            }
        }
    }

	//
	// MARK: - Init
	//

	enum Init {
		struct Request {
		}

		struct Response {
		}

		struct ViewModel {
            let loadingMessage: String
		}
	}
    
    //
    // MARK: - Load title
    //
    
    enum LoadTitle {
        struct Request {
            let labelId: String
        }
        
        struct Response {
            let item: MailboxSidebar.Item
            let numItems: Int
        }
        
        struct ViewModel {
            let title: String
            let subtitle: String?
        }
    }
    
}
