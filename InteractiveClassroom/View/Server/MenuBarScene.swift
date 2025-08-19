#if os(macOS)
import SwiftUI
import SwiftData

/// macOS-specific scenes presented from the menu bar.
struct MenuBarScene: Scene {
    @ObservedObject var pairingService: PairingService
    @ObservedObject var courseSessionService: CourseSessionService
    @ObservedObject var interactionService: InteractionService
    let container: ModelContainer
    @StateObject private var overlayManager: OverlayWindowManager
    @StateObject private var menuBarCoordinator = MenuBarCoordinator()

    init(
        pairingService: PairingService,
        courseSessionService: CourseSessionService,
        interactionService: InteractionService,
        container: ModelContainer
    ) {
        self.pairingService = pairingService
        self.courseSessionService = courseSessionService
        self.interactionService = interactionService
        self.container = container
        _overlayManager = StateObject(
            wrappedValue: OverlayWindowManager(
                pairingService: pairingService,
                courseSessionService: courseSessionService,
                interactionService: interactionService,
                menuBarCoordinator: menuBarCoordinator
            )
        )
    }

    var body: some Scene {
        MenuBarExtra("InteractiveClassroom", systemImage: "graduationcap") {
            MenuBarView()
                .environmentObject(pairingService)
                .environmentObject(courseSessionService)
                .environmentObject(interactionService)
                .environmentObject(overlayManager)
                .environmentObject(menuBarCoordinator)
        }
        .id(menuBarCoordinator.refreshID)
        .menuBarExtraStyle(.menu)
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
