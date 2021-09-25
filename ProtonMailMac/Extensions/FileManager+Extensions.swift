//
//  FileManager+Extensions.swift
//  ProtonMailMac
//
//  Created by Marcel Piešťanský on 25.09.2021.
//  Copyright © 2021 marpies. All rights reserved.
//

import Foundation

extension FileManager {
    
    var attachmentsDirectory: URL {
        let url: URL = self.temporaryDirectory.appendingPathComponent("attachments", isDirectory: true)
        if !self.fileExists(atPath: url.path) {
            do {
                try self.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
            } catch {
                PMLog.D("Error creating attachments directory: \(error)")
            }
        }
        return url
    }
    
}
