//
//  InteractiveClassroomApp.swift
//  InteractiveClassroom
//
//  Created by zhb on 2025/8/12.
//

import SwiftUI

@main
struct InteractiveClassroomApp: App {
#if os(macOS)
    @NSApplicationDelegateAdaptor(OverlayAppDelegate.self) var appDelegate
#endif
    var body: some Scene {
#if os(macOS)
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
