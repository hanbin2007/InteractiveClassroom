#if os(macOS)
import SwiftUI
import AppKit

/// Content displayed in the menu bar extra for macOS builds.
struct MenuBarView: View {
    @EnvironmentObject private var pairingService: PairingService
    @EnvironmentObject private var courseSessionService: CourseSessionService
    @EnvironmentObject private var interactionService: InteractionService
    @EnvironmentObject private var overlayManager: OverlayWindowManager
    @Environment(\.openWindow) private var openWindow
    @StateObject private var viewModel = MenuBarViewModel()

    var body: some View {
        Group {
            Text("Teacher Key: \(pairingService.teacherCode ?? "")")
                .opacity(pairingService.teacherCode == nil ? 0 : 1)
            Text("Student Key: \(pairingService.studentCode ?? "")")
                .opacity(pairingService.studentCode == nil ? 0 : 1)
            Text(pairingService.connectionStatus)
            Divider()
            Button(pairingService.teacherCode == nil ? "Open Classroom" : "End Class") {
                if pairingService.teacherCode == nil {
                    viewModel.openWindowIfNeeded(id: "courseSelection", openWindow: openWindow)
                } else {
                    overlayManager.closeOverlay()
                    courseSessionService.endClass()
                    viewModel.openWindowIfNeeded(id: "courseSelection", openWindow: openWindow)
                }
            }
            Button("Clients") {
                viewModel.openWindowIfNeeded(id: "clients", openWindow: openWindow)
            }
            Button("Courses") {
                viewModel.openWindowIfNeeded(id: "courseManager", openWindow: openWindow)
            }
            if #available(macOS 13, *) {
                SettingsLink {
                    Text("Settings")
                }
            } else {
                Button("Settings") {
                    NSApp.sendAction(Selector(("showPreferencesWindow:")), to: nil, from: nil)
                }
            }
            Divider()
            Button("Quit") {
                NSApp.terminate(nil)
            }
        }
    }
}
#Preview {
    let pairing = PairingService()
    let interaction = InteractionService(manager: pairing)
    let courseService = CourseSessionService(manager: pairing, interactionService: interaction)
    let overlayManager = OverlayWindowManager(
        pairingService: pairing,
        courseSessionService: courseService,
        interactionService: interaction
    )
    return MenuBarView()
        .environmentObject(pairing)
        .environmentObject(courseService)
        .environmentObject(interaction)
        .environmentObject(overlayManager)
}
#endif
