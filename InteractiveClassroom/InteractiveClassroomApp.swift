//
//  InteractiveClassroomApp.swift
//  InteractiveClassroom
//
//  Created by zhb on 2025/8/12.
//

import SwiftUI
import SwiftData

@main
struct InteractiveClassroomApp: App {
#if os(macOS)
    @NSApplicationDelegateAdaptor(OverlayAppDelegate.self) var appDelegate
#endif
    @StateObject private var connectionManager: PeerConnectionManager
    private let container: ModelContainer

    init() {
        let schema = Schema([Item.self, ClientInfo.self])
        let container = try! ModelContainer(for: schema)
        self.container = container

        let context = ModelContext(container)
        let manager = PeerConnectionManager(modelContext: context)
        _connectionManager = StateObject(wrappedValue: manager)
        // Start hosting as soon as the application launches so the server is immediately available.
        manager.startHosting()
    }

    var body: some Scene {
#if os(macOS)
        MenuBarExtra("InteractiveClassroom", systemImage: "graduationcap") {
            MenuBarView()
                .environmentObject(connectionManager)
        }
        .modelContainer(container)
        Settings {
            SettingsView()
                .environmentObject(connectionManager)
        }
        .modelContainer(container)
#else
        WindowGroup {
            ContentView()
                .environmentObject(connectionManager)
        }
        .modelContainer(container)
#endif
    }
}
