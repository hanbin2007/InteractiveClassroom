#if os(macOS)
import SwiftUI
import AppKit

/// Content displayed in the menu bar extra for macOS builds.
struct MenuBarView: View {
    @EnvironmentObject private var connectionManager: PeerConnectionManager
    @Environment(\.openWindow) private var openWindow

    /// Closes any existing overlay windows.
    private func closeOverlayWindows() {
        NSApp.windows.filter { $0.identifier?.rawValue == "overlay" }.forEach { $0.close() }
    }

    var body: some View {
        Group {
            if connectionManager.currentLesson == nil {
                Button("Start Class") {
                    openWindow(id: "courseSelection")
                }
            } else {
                Button("End Class") {
                    connectionManager.stopHosting()
                    connectionManager.currentCourse = nil
                    connectionManager.currentLesson = nil
                    closeOverlayWindows()
                }
            }
            Button("Show Screen") {
                openWindow(id: "overlay")
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
                openWindow(id: "overlay")
            } else {
                closeOverlayWindows()
            }
        }
    }
}
#Preview {
    MenuBarView()
        .environmentObject(PeerConnectionManager())
}
#endif
