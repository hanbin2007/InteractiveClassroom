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
        let controller = NSHostingController(rootView: ScreenOverlayView()
            .environmentObject(connectionManager))
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

    /// Opens a window identified by `id` if one isn't already visible.
    /// If the window exists, it is brought to the front instead of creating a duplicate.
    private func openWindowIfNeeded(id: String) {
        if let window = NSApp.windows.first(where: { $0.identifier?.rawValue == id }) {
            window.makeKeyAndOrderFront(nil)
        } else {
            openWindow(id: id)
        }
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
            if connectionManager.teacherCode == nil {
                Button("Open Classroom") {
                    openWindowIfNeeded(id: "courseSelection")
                }
            } else {
                Button("End Class") {
                    connectionManager.endClass()
                    connectionManager.currentCourse = nil
                    connectionManager.currentLesson = nil
                    closeOverlay()
                }
            }
            Button("Clients") {
                openWindowIfNeeded(id: "clients")
            }
            Button("Courses") {
                openWindowIfNeeded(id: "courseManager")
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
        .onChange(of: connectionManager.teacherCode) { code in
            if code != nil {
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
