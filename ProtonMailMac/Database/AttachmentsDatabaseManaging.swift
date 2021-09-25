//
//  AttachmentsDatabaseManaging.swift
//  ProtonMailMac
//
//  Created by Marcel Piešťanský on 25.09.2021.
//  Copyright © 2021 marpies. All rights reserved.
//

import Foundation

protocol AttachmentsDatabaseManaging {
    func update(attachment: Attachment, fileUrl: URL, completion: @escaping (NSError?) -> Void)
}
