//
//  MessagesInteractor.swift
//  ProtonMailMac
//
//  Created by Marcel Piešťanský on 05.09.2021.
//  Copyright (c) 2021 marpies. All rights reserved.
//

import Foundation

protocol MessagesBusinessLogic {
    
}

protocol MessagesDataStore {
	
}

class MessagesInteractor: MessagesBusinessLogic, MessagesDataStore, MessagesWorkerDelegate {

	var worker: MessagesWorker?

	var presenter: MessagesPresentationLogic?
    
}
