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
            Text("Teacher Key: \(pairingService.teacherCode ?? "—")")
                .disabled(pairingService.teacherCode == nil)
            Text("Student Key: \(pairingService.studentCode ?? "—")")
                .disabled(pairingService.studentCode == nil)
            Text(pairingService.connectionStatus)
            Divider()
            // Open Classroom
            Button("Open Classroom") {
                Task { @MainActor in
                    viewModel.openWindowIfNeeded(id: "courseSelection", openWindow: openWindow)
                }
            }.disabled(pairingService.teacherCode != nil)
            
            Button("End Class") {
                // 等菜单关闭一个节拍，避免在 tracking 期做大动作
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    Task { @MainActor in
                        overlayManager.closeOverlay()
                        courseSessionService.endClass()
                        viewModel.openWindowIfNeeded(id: "courseSelection", openWindow: openWindow)
                    }
                }
            }
            .disabled(pairingService.teacherCode == nil)

            // Clients
            Button("Clients") {
                Task { @MainActor in
                    viewModel.openWindowIfNeeded(id: "clients", openWindow: openWindow)
                }
            }

            // Courses
            Button("Courses") {
                Task { @MainActor in
                    viewModel.openWindowIfNeeded(id: "courseManager", openWindow: openWindow)
                }
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
