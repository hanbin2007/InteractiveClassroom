#if os(macOS)
import AppKit
import SwiftUI
import SwiftData

/// Manages the window that lists all connected clients.
final class ClientsWindowController {
    static let shared = ClientsWindowController()
    private var window: NSWindow?

    func show(container: ModelContainer?, connectionManager: PeerConnectionManager) {
        guard let container else { return }
        if window == nil {
            let contentView = ClientsListView()
                .environmentObject(connectionManager)
                .modelContainer(container)
            let hosting = NSHostingView(rootView: contentView)
            let win = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 600, height: 400),
                               styleMask: [.titled, .closable, .resizable],
                               backing: .buffered,
                               defer: false)
            win.center()
            win.contentView = hosting
            window = win
        }
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
#endif
