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
    @StateObject private var pairingService: PairingService
    @StateObject private var courseSessionService: CourseSessionService
    @StateObject private var interactionService: InteractionService
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

        let pairing = PairingService(modelContext: container.mainContext)
        _pairingService = StateObject(wrappedValue: pairing)
        let interaction = InteractionService(manager: pairing)
        _interactionService = StateObject(wrappedValue: interaction)
        _courseSessionService = StateObject(wrappedValue: CourseSessionService(manager: pairing, interactionService: interaction))
    }

    var body: some Scene {
#if os(macOS)
        MenuBarExtra("InteractiveClassroom", systemImage: "graduationcap") {
            MenuBarView()
                .environmentObject(pairingService)
                .environmentObject(courseSessionService)
                .environmentObject(interactionService)
        }
        .modelContainer(container)
        Settings {
            SettingsView()
                .environmentObject(pairingService)
                .environmentObject(courseSessionService)
                .environmentObject(interactionService)
        }
        .modelContainer(container)
        WindowGroup(id: "courseSelection") {
            CourseSelectionView()
                .environmentObject(courseSessionService)
                .environmentObject(pairingService)
        }
        .modelContainer(container)
        WindowGroup(id: "clients") {
            ClientsListView()
                .environmentObject(pairingService)
                .environmentObject(courseSessionService)
                .environmentObject(interactionService)
        }
        .modelContainer(container)
        WindowGroup(id: "courseManager") {
            CourseManagerView()
                .environmentObject(pairingService)
                .environmentObject(courseSessionService)
                .environmentObject(interactionService)
        }
        .modelContainer(container)
#else
        WindowGroup {
            ContentView()
                .environmentObject(pairingService)
                .environmentObject(courseSessionService)
                .environmentObject(interactionService)
        }
        .modelContainer(container)
#endif
    }
}
