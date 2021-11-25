//
//  MailboxModels.swift
//  ProtonMailMac
//
//  Created by Marcel Piešťanský on 16.09.2021.
//  Copyright (c) 2021 marpies. All rights reserved.
//

import Foundation
import AppKit

enum Mailbox {
    
    /// Number of messages or conversations displayed in the list on a single page.
    static let numItemsPerPage: Int = 50
    
    enum Page {
        case first, previous, next, last, specific(page: String)
        
        class ViewModel {
            let title: String?
            let image: NSImage?
            let tooltip: String

            init(title: String?, image: NSImage?, tooltip: String) {
                self.title = title
                self.image = image
                self.tooltip = tooltip
            }
        }
    }
    
    enum SelectionType {
        /// No selection is made.
        case none
        
        /// Selected messages (array of ids).
        case messages([String])
        
        /// Selected conversations (array of ids).
        case conversations([String])
    }
    
    enum TableItem {
        enum Kind {
            case conversation, message
        }
        
        class ViewModel {
            let type: Mailbox.TableItem.Kind
            let id: String
            let title: String
            let subtitle: String
            let time: String
            let isRead: Bool
            let starIcon: Messages.Star.ViewModel
            let folders: [Messages.Folder.ViewModel]?
            let labels: [Messages.Label.ViewModel]?
            let attachmentIcon: Messages.Attachment.ViewModel?

            init(type: Mailbox.TableItem.Kind, id: String, title: String, subtitle: String, time: String, isRead: Bool, starIcon: Messages.Star.ViewModel, folders: [Messages.Folder.ViewModel]?, labels: [Messages.Label.ViewModel]?, attachmentIcon: Messages.Attachment.ViewModel?) {
                self.type = type
                self.id = id
                self.title = title
                self.subtitle = subtitle
                self.time = time
                self.isRead = isRead
                self.starIcon = starIcon
                self.folders = folders
                self.labels = labels
                self.attachmentIcon = attachmentIcon
            }
        }
    }
    
    //
    // MARK: - Load items
    //
    
    enum LoadItems {
        struct Request {
            let labelId: String
        }
        
        class ViewModel {
            let items: [Mailbox.TableItem.ViewModel]
            let removeErrorView: Bool
            
            init(items: [Mailbox.TableItem.ViewModel], removeErrorView: Bool) {
                self.items = items
                self.removeErrorView = removeErrorView
            }
        }
    }
    
    //
    // MARK: - Update items
    //
    
    enum UpdateItems {
        class ViewModel {
            let items: [Mailbox.TableItem.ViewModel]
            let removeSet: IndexSet?
            let insertSet: IndexSet?
            let updateSet: IndexSet?
            
            init(items: [Mailbox.TableItem.ViewModel], removeSet: IndexSet?, insertSet: IndexSet?, updateSet: IndexSet?) {
                self.items = items
                self.removeSet = removeSet
                self.insertSet = insertSet
                self.updateSet = updateSet
            }
        }
    }
    
    //
    // MARK: - Update item
    //
    
    enum UpdateItem {
        class ViewModel {
            let item: Mailbox.TableItem.ViewModel
            let index: Int
            
            init(item: Mailbox.TableItem.ViewModel, index: Int) {
                self.item = item
                self.index = index
            }
        }
    }
    
    //
    // MARK: - Refresh items
    //
    
    enum RefreshItems {
        class ViewModel {
            let items: [(item: Mailbox.TableItem.ViewModel, index: Int)]
            let indexSet: IndexSet

            init(items: [(Mailbox.TableItem.ViewModel, Int)], indexSet: IndexSet) {
                self.items = items
                self.indexSet = indexSet
            }
        }
    }
    
    //
    // MARK: - Load page
    //
    
    enum LoadPage {
        struct Request {
            let type: Mailbox.Page
        }
    }
    
    //
    // MARK: - Update item star
    //
    
    enum UpdateItemStar {
        struct Request {
            let id: String
            let isOn: Bool
            let type: Mailbox.TableItem.Kind
        }
    }
    
    //
    // MARK: - Items did select
    //
    
    enum ItemsDidSelect {
        struct Request {
            let ids: [String]
            let type: Mailbox.TableItem.Kind
        }
        
        struct Response {
            let type: Mailbox.SelectionType
        }
        
        struct ViewModel {
            let type: Mailbox.SelectionType
        }
    }
    
    //
    // MARK: - Load conversation
    //
    
    enum LoadConversation {
        struct Response {
            let id: String
        }
        
        struct ViewModel {
            let id: String
        }
    }
    
    //
    // MARK: - Load error
    //
    
    enum LoadError {
        struct Response {
            let error: NSError
        }
        
        struct ViewModel {
            let message: String
            let button: String
        }
    }
    
    //
    // MARK: - Page count update
    //
    
    enum PageCountUpdate {
        struct Response {
            let currentPage: Int
            let numPages: Int
        }
        
        class ViewModel {
            let pages: [Mailbox.Page.ViewModel]
            let selectedIndex: Int
            let firstPageIcon: Mailbox.Page.ViewModel
            let previousPageIcon: Mailbox.Page.ViewModel
            let lastPageIcon: Mailbox.Page.ViewModel
            let nextPageIcon: Mailbox.Page.ViewModel
            let previousButtonsEnabled: Bool
            let nextButtonsEnabled: Bool

            init(pages: [Mailbox.Page.ViewModel], selectedIndex: Int, firstPageIcon: Mailbox.Page.ViewModel, previousPageIcon: Mailbox.Page.ViewModel, lastPageIcon: Mailbox.Page.ViewModel, nextPageIcon: Mailbox.Page.ViewModel, previousButtonsEnabled: Bool, nextButtonsEnabled: Bool) {
                self.pages = pages
                self.selectedIndex = selectedIndex
                self.firstPageIcon = firstPageIcon
                self.previousPageIcon = previousPageIcon
                self.lastPageIcon = lastPageIcon
                self.nextPageIcon = nextPageIcon
                self.previousButtonsEnabled = previousButtonsEnabled
                self.nextButtonsEnabled = nextButtonsEnabled
            }
        }
    }
    
}
