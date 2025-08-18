#if os(macOS)
import SwiftUI
import AppKit

/// Content displayed in the menu bar extra for macOS builds.
struct MenuBarView: View {
    @EnvironmentObject private var pairingService: PairingService
    @EnvironmentObject private var courseSessionService: CourseSessionService
    @EnvironmentObject private var interactionService: InteractionService
    @Environment(\.openWindow) private var openWindow
    @StateObject private var viewModel = MenuBarViewModel()
    @StateObject private var overlayManager = OverlayWindowManager()

    var body: some View {
        Group {
            if let t = pairingService.teacherCode,
               let s = pairingService.studentCode {
                Text("Teacher Key: \(t)")
                Text("Student Key: \(s)")
            }
            Text(pairingService.connectionStatus)
            Divider()
            if pairingService.teacherCode == nil {
                Button("Open Classroom") {
                    viewModel.openWindowIfNeeded(id: "courseSelection", openWindow: openWindow)
                }
            } else {
                Button("End Class") {
                    overlayManager.closeOverlay()
                    courseSessionService.endClass()
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
        .onChange(of: pairingService.teacherCode) { code in
            if code != nil {
                overlayManager.openOverlay(
                    pairingService: pairingService,
                    courseSessionService: courseSessionService,
                    interactionService: interactionService
                )
            } else {
                overlayManager.closeOverlay()
            }
        }
    }
}
#Preview {
    let pairing = PairingService()
    let interaction = InteractionService(manager: pairing)
    let courseService = CourseSessionService(manager: pairing, interactionService: interaction)
    return MenuBarView()
        .environmentObject(pairing)
        .environmentObject(courseService)
        .environmentObject(interaction)
}
#endif
