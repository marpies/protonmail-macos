//
//  MessagesPresenter.swift
//  ProtonMailMac
//
//  Created by Marcel Piešťanský on 05.09.2021.
//  Copyright (c) 2021 marpies. All rights reserved.
//

import AppKit

protocol MessagesPresentationLogic {
    
}

class MessagesPresenter: MessagesPresentationLogic {
	weak var viewController: MessagesDisplayLogic?
    
    private let dateFormatter: DateFormatter
    
    init() {
        self.dateFormatter = DateFormatter()
        self.dateFormatter.locale = Locale.current
    }

}
