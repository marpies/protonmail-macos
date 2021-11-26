//
//  ComposerPresenter.swift
//  ProtonMailMac
//
//  Created by Marcel Piešťanský on 26.11.2021.
//  Copyright (c) 2021 marpies. All rights reserved.
//

import AppKit

protocol ComposerPresentationLogic {
	func presentInitialData(response: Composer.Init.Response)
    func presentToolbarUpdate(response: Composer.UpdateToolbar.Response)
}

class ComposerPresenter: ComposerPresentationLogic {
	weak var viewController: ComposerDisplayLogic?

	//
	// MARK: - Present initial data
	//

	func presentInitialData(response: Composer.Init.Response) {
		let viewModel = Composer.Init.ViewModel()
		self.viewController?.displayInitialData(viewModel: viewModel)
	}
    
    //
    // MARK: - Present toolbar update
    //
    
    func presentToolbarUpdate(response: Composer.UpdateToolbar.Response) {
        let identifiers: [NSToolbarItem.Identifier] = self.toolbarIdentifiers
        
        let items: [Main.ToolbarItem.ViewModel] = identifiers.map {
            self.getToolbarItem(id: $0, response: response)
        }
        
        let viewModel: Composer.UpdateToolbar.ViewModel = Composer.UpdateToolbar.ViewModel(identifiers: identifiers, items: items)
        self.viewController?.displayToolbarUpdate(viewModel: viewModel)
    }
    
    //
    // MARK: - Private
    //
    
    private var toolbarIdentifiers: [NSToolbarItem.Identifier] {
        return [
            .sendMail,
            .flexibleSpace,
            .addAttachment
        ]
    }
    
    private func getToolbarItem(id: NSToolbarItem.Identifier, response: Composer.UpdateToolbar.Response) -> Main.ToolbarItem.ViewModel {
        switch id {
        case .sendMail, .addAttachment:
            let label: String = self.getToolbarItemLabel(id: id)
            let tooltip: String = self.getToolbarItemTooltip(id: id)
            let icon: String = self.getToolbarItemIcon(id: id)
            let isEnabled: Bool = self.getToolbarItemEnabled(id: id, canSend: response.canSend)
            return .button(id: id, label: label, tooltip: tooltip, icon: icon, isEnabled: isEnabled)
            
        case .flexibleSpace, .space:
            return .spacer
            
        default:
            fatalError("Unknown toolbar item id: \(id.rawValue).")
        }
    }
    
    private func getToolbarItemLabel(id: NSToolbarItem.Identifier) -> String {
        switch id {
        case .sendMail:
            return NSLocalizedString("toolbarSendMailLabel", comment: "")
        case .addAttachment:
            return NSLocalizedString("toolbarAddAttachmentLabel", comment: "")
        default:
            fatalError("Toolbar item \(id.rawValue) does not have a label.")
        }
    }
    
    private func getToolbarItemTooltip(id: NSToolbarItem.Identifier) -> String {
        switch id {
        case .sendMail:
            return NSLocalizedString("toolbarSendMailTooltip", comment: "")
        case .addAttachment:
            return NSLocalizedString("toolbarAddAttachmentTooltip", comment: "")
        default:
            fatalError("Toolbar item \(id.rawValue) does not have a tooltip.")
        }
    }
    
    private func getToolbarItemIcon(id: NSToolbarItem.Identifier) -> String {
        switch id {
        case .sendMail:
            return "paperplane"
        case .addAttachment:
            return "paperclip"
        default:
            fatalError("Toolbar item \(id.rawValue) does not have an icon.")
        }
    }
    
    private func getToolbarItemEnabled(id: NSToolbarItem.Identifier, canSend: Bool) -> Bool {
        switch id {
        case .sendMail:
            return canSend
            
        default:
            return true
        }
    }

}
