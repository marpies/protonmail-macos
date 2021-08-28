//
//  LabelsResponse.swift
//  ProtonMailMac
//
//  Created by Marcel Piešťanský on 27.08.2021.
//  Copyright © 2021 marpies. All rights reserved.
//

import Foundation

final class LabelsResponse: Response {
    private(set) var labels: [[String : Any]]?
    
    override func parseResponse(_ response: [String: Any]) -> Bool {
        self.labels =  response["Labels"] as? [[String: Any]]
        return true
    }
}
