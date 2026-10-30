//
//  Corvus_MacApp.swift
//  Corvus Mac
//
//  Created by Ufuk Celen on 30.10.2026.
//

import SwiftUI
import AppKit

@main
struct Corvus_MacApp: App {
    @StateObject private var manager = CorvusManager.shared
    
    init() {
        // Set Dock Icon dynamically to the cyber-raven logo
        if let logo = NSImage(named: "CorvusLogo") {
            NSApplication.shared.applicationIconImage = logo
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 980, idealWidth: 1100, minHeight: 640, idealHeight: 740)
                .preferredColorScheme(manager.appThemeMode.colorScheme)
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified)
        .commands {
            SidebarCommands()
        }
    }
}
