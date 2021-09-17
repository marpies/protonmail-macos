//
//  MessageLabelPresenting.swift
//  ProtonMailMac
//
//  Created by Marcel Piešťanský on 17.09.2021.
//  Copyright © 2021 marpies. All rights reserved.
//

import Foundation

protocol MessageLabelPresenting {
    func getLabel(response: Messages.Label.Response) -> Messages.Label.ViewModel
}

extension MessageLabelPresenting {
    
    func getLabel(response: Messages.Label.Response) -> Messages.Label.ViewModel {
        return Messages.Label.ViewModel(id: response.id, title: response.title, color: response.color)
    }
    
}
