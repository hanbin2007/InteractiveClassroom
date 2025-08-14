#if os(macOS)
import SwiftUI
import AppKit

/// Content displayed in the menu bar extra for macOS builds.
struct MenuBarView: View {
    @EnvironmentObject private var connectionManager: PeerConnectionManager
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        if connectionManager.currentLesson == nil {
            Button("Start Class") {
                openWindow(id: "courseSelection")
            }
        } else {
            Button("End Class") {
                connectionManager.stopHosting()
                connectionManager.currentCourse = nil
                connectionManager.currentLesson = nil
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
}
#Preview {
    MenuBarView()
        .environmentObject(PeerConnectionManager())
}
#endif
