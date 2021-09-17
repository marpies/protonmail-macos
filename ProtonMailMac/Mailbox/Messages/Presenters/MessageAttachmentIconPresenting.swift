//
//  MessageAttachmentIconPresenting.swift
//  ProtonMailMac
//
//  Created by Marcel Piešťanský on 17.09.2021.
//  Copyright © 2021 marpies. All rights reserved.
//

import Foundation

protocol MessageAttachmentIconPresenting {
    func getAttachmentIcon(numAttachments: Int) -> Messages.Attachment.ViewModel?
}

extension MessageAttachmentIconPresenting {
    
    func getAttachmentIcon(numAttachments: Int) -> Messages.Attachment.ViewModel? {
        if numAttachments > 0 {
            let format: String = NSLocalizedString("num_attachments", comment: "")
            let title: String = String.localizedStringWithFormat(format, numAttachments)
            return Messages.Attachment.ViewModel(icon: "paperclip", title: title)
        }
        return nil
    }
    
}
