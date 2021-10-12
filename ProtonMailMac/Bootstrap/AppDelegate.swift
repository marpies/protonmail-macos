//
//  AppDelegate.swift
//  ProtonMailMac
//
//  Created by Marcel Piešťanský on 21.08.2021.
//

import Cocoa
import Swinject

@main
class AppDelegate: NSObject, NSApplicationDelegate {

    private let assembler = Assembler()
    private lazy var mainController: MainWindowController = MainWindowController(resolver: self.assembler.resolver)

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        self.assembler.apply(assemblies: [
            BootstrapAssembly(),
            DatabaseAssembly(),
            ManagersAssembly(),
            SetupAssembly(),
            SignInAssembly(),
            MailboxSidebarAssembly(),
            ConversationDetailsAssembly(),
            MailboxAssembly(),
            MainAssembly(),
            ServicesAssembly()
        ])
        
        self.mainController.showWindow(nil)
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }


}

