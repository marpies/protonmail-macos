//
//  DownloadAttachmentRequest.swift
//  ProtonMailMac
//
//  Created by Marcel Piešťanský on 25.09.2021.
//  Copyright © 2021 marpies. All rights reserved.
//

import Foundation

struct DownloadAttachmentRequest: DownloadRequest {
    
    var authCredential: AuthCredential?
    
    var path: String {
        return AttachmentsAPI.path + "/\(self.attachmentId)"
    }
    
    let attachmentId: String
    let destinationURL: URL

    init(attachmentId: String, destinationURL: URL) {
        self.attachmentId = attachmentId
        self.destinationURL = destinationURL
    }
    
}
