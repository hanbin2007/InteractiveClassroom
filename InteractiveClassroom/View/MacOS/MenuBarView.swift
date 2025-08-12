#if os(macOS)
import SwiftUI
import AppKit

/// Content displayed in the menu bar extra for macOS builds.
struct MenuBarView: View {
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        Button("Show Screen") {
            openWindow(id: "ScreenOverlay")
        }
        Button("Settings") {
            NSApp.sendAction(#selector(NSApplication.showPreferencesWindow(_:)), to: nil, from: nil)
        }
        Divider()
        Button("Quit") {
            NSApp.terminate(nil)
        }
    }
}
#endif
