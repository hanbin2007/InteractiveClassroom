#if os(macOS)
import SwiftUI
import AppKit

/// Content displayed in the menu bar extra for macOS builds.
struct MenuBarView: View {
    var body: some View {
        Button("Show Screen") {
            OverlayWindowController.shared.show()
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
