//
//  InteractiveClassroomApp.swift
//  InteractiveClassroom
//
//  Created by zhb on 2025/8/12.
//

import SwiftUI

@main
struct InteractiveClassroomApp: App {
    var body: some Scene {
#if os(macOS)
        WindowGroup(id: "ScreenOverlay") {
            ScreenOverlayView()
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 800, height: 600)
        MenuBarExtra("InteractiveClassroom", systemImage: "graduationcap") {
            MenuBarView()
        }
        Settings {
            SettingsView()
        }
#else
        WindowGroup {
            ContentView()
        }
#endif
    }
}
