#if os(macOS)
import SwiftUI
import AppKit

/// Content displayed in the menu bar extra for macOS builds.
struct MenuBarView: View {
    var body: some View {
        Button("Show Screen") {
            OverlayWindowController.shared.show()
        }
        Button("Settings") {
            if #available(macOS 13, *) {
                NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
            } else {
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
