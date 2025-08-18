#if os(macOS)
import SwiftUI
import SwiftData

/// macOS-specific scenes presented from the menu bar.
struct MenuBarScene: Scene {
    @ObservedObject var pairingService: PairingService
    @ObservedObject var courseSessionService: CourseSessionService
    @ObservedObject var interactionService: InteractionService
    let container: ModelContainer

    var body: some Scene {
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
    }
}
#endif
