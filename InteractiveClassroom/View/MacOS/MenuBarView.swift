#if os(macOS)
import SwiftUI
import AppKit

/// Content displayed in the menu bar extra for macOS builds.
struct MenuBarView: View {
    @EnvironmentObject private var connectionManager: PeerConnectionManager
    @Environment(\.openWindow) private var openWindow
    @State private var overlayWindow: NSWindow?

    /// Presents the full-screen overlay window.
    private func openOverlay() {
        closeOverlay()
        let controller = NSHostingController(rootView: ScreenOverlayView())
        let window = NSWindow(contentViewController: controller)
        window.isReleasedWhenClosed = false
        window.makeKeyAndOrderFront(nil)
        overlayWindow = window
    }

    /// Closes any existing overlay windows.
    private func closeOverlay() {
        overlayWindow?.close()
        overlayWindow = nil
        NSApp.windows.filter { $0.identifier?.rawValue == "overlay" }.forEach { $0.close() }
    }

    var body: some View {
        Group {
            if let t = connectionManager.teacherCode,
               let s = connectionManager.studentCode {
                Text("Teacher Key: \(t)")
                Text("Student Key: \(s)")
            }
            Text(connectionManager.connectionStatus)
            Divider()
            if connectionManager.currentLesson == nil {
                Button("Start Class") {
                    openWindow(id: "courseSelection")
                }
            } else {
                Button("End Class") {
                    connectionManager.stopHosting()
                    connectionManager.currentCourse = nil
                    connectionManager.currentLesson = nil
                    closeOverlay()
                }
            }
            if connectionManager.classStarted {
                Button("Show Screen") {
                    openOverlay()
                }
            }
            Button("Clients") {
                openWindow(id: "clients")
            }
            Button("Courses") {
                openWindow(id: "courseManager")
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
        .onChange(of: connectionManager.classStarted) { started in
            if started {
                openOverlay()
            } else {
                closeOverlay()
            }
        }
    }
}
#Preview {
    MenuBarView()
        .environmentObject(PeerConnectionManager())
}
#endif
