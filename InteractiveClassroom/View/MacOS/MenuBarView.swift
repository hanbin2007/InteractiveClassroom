#if os(macOS)
import SwiftUI
import AppKit
import SwiftData

/// Content displayed in the menu bar extra for macOS builds.
struct MenuBarView: View {
    @EnvironmentObject private var connectionManager: PeerConnectionManager

    var body: some View {
        if connectionManager.currentLesson == nil {
            Button("Start Class") {
                if let container = connectionManager.modelContext?.container {
                    CourseSelectionWindowController.shared.show(container: container,
                                                               connectionManager: connectionManager)
                }
            }
        } else {
            Button("End Class") {
                connectionManager.stopHosting()
                connectionManager.currentCourse = nil
                connectionManager.currentLesson = nil
            }
        }
        Button("Show Screen") {
            OverlayWindowController.shared.show()
        }
        Button("Clients") {
            if let container = connectionManager.modelContext?.container {
                ClientsWindowController.shared.show(container: container,
                                                   connectionManager: connectionManager)
            }
        }
        Button("Courses") {
            if let container = connectionManager.modelContext?.container {
                CourseManagerWindowController.shared.show(container: container)
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
#endif
