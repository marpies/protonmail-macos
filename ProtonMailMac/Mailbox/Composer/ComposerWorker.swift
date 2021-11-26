//
//  ComposerWorker.swift
//  ProtonMailMac
//
//  Created by Marcel Piešťanský on 26.11.2021.
//  Copyright (c) 2021 marpies. All rights reserved.
//

import Foundation
import Swinject

protocol ComposerWorkerDelegate: AnyObject {
    func composerDidLoad(response: Composer.Init.Response)
    func composerToolbarDidUpdate(response: Composer.UpdateToolbar.Response)
}

class ComposerWorker {

	private let resolver: Resolver

	weak var delegate: ComposerWorkerDelegate?

	init(resolver: Resolver) {
		self.resolver = resolver
	}

	func loadInitialData(request: Composer.Init.Request) {
        self.updateToolbar()
        
        let response: Composer.Init.Response = Composer.Init.Response()
        self.delegate?.composerDidLoad(response: response)
	}
    
    //
    // MARK: - Private
    //
    
    private func updateToolbar() {
        let response: Composer.UpdateToolbar.Response = Composer.UpdateToolbar.Response(canSend: false)
        self.delegate?.composerToolbarDidUpdate(response: response)
    }

}
