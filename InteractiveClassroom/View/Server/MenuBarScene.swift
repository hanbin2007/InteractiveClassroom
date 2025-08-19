#if os(macOS)
import SwiftUI
import SwiftData

/// macOS-specific scenes presented from the menu bar.
struct MenuBarScene: Scene {
    @ObservedObject var pairingService: PairingService
    @ObservedObject var courseSessionService: CourseSessionService
    @ObservedObject var interactionService: InteractionService
    @ObservedObject var menuBarController: MenuBarExtraController
    let container: ModelContainer
    @StateObject private var overlayManager: OverlayWindowManager

    init(
        pairingService: PairingService,
        courseSessionService: CourseSessionService,
        interactionService: InteractionService,
        menuBarController: MenuBarExtraController,
        container: ModelContainer
    ) {
        self.pairingService = pairingService
        self.courseSessionService = courseSessionService
        self.interactionService = interactionService
        self.menuBarController = menuBarController
        self.container = container
        _overlayManager = StateObject(
            wrappedValue: OverlayWindowManager(
                pairingService: pairingService,
                courseSessionService: courseSessionService,
                interactionService: interactionService
            )
        )
    }

    var body: some Scene {
        Group {
            if menuBarController.isVisible {
                MenuBarExtra("InteractiveClassroom", systemImage: "graduationcap") {
                    MenuBarView()
                        .environmentObject(pairingService)
                        .environmentObject(courseSessionService)
                        .environmentObject(interactionService)
                        .environmentObject(menuBarController)
                        .environmentObject(overlayManager)
                }
                .modelContainer(container)
            }
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
}
#endif
