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
    @StateObject private var connectionManager: PeerConnectionManager
    private let container: ModelContainer

    init() {
        let schema = Schema([ClientInfo.self, Course.self, Lesson.self])
        let container: ModelContainer
        do {
            container = try ModelContainer(for: schema)
        } catch {
            #if DEBUG
            print("Unresolved error loading container \(error)")
            #endif
            let storeURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first?.appendingPathComponent("default.store")
            if let url = storeURL {
                try? FileManager.default.removeItem(at: url)
            }
            do {
                container = try ModelContainer(for: schema)
            } catch {
                container = try! ModelContainer(for: schema, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
                #if DEBUG
                print("Failed to load persistent container: \(error). Using in-memory store.")
                #endif
            }
        }
        self.container = container

        let context = ModelContext(container)
        let manager = PeerConnectionManager(modelContext: context)
        _connectionManager = StateObject(wrappedValue: manager)
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
        WindowGroup(id: "courseSelection") {
            CourseSelectionView()
                .environmentObject(connectionManager)
        }
        .modelContainer(container)
        if connectionManager.classStarted {
            Window("Overlay", id: "overlay") {
                ScreenOverlayView()
            }
            .modelContainer(container)
        }
        WindowGroup(id: "clients") {
            ClientsListView()
                .environmentObject(connectionManager)
        }
        .modelContainer(container)
        WindowGroup(id: "courseManager") {
            CourseManagerView()
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
