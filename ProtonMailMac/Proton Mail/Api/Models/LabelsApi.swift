//
//  LabelsApi.swift
//  ProtonMailMac
//
//  Created by Marcel Piešťanský on 27.08.2021.
//  Copyright © 2021 marpies. All rights reserved.
//

import Foundation

enum LabelsAPI {
    static let path: String = "labels"
}

enum LabelType: Int {
    case labels = 1
    case contacts = 2
}
