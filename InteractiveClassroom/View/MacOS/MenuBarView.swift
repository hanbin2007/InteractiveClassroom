#if os(macOS)
import SwiftUI
import AppKit
import SwiftData

/// Content displayed in the menu bar extra for macOS builds.
struct MenuBarView: View {
    @EnvironmentObject private var connectionManager: PeerConnectionManager
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        Button("Show Screen") {
            OverlayWindowController.shared.show()
        }
        Button("Clients") {
            ClientsWindowController.shared.show(container: modelContext.container, connectionManager: connectionManager)
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
