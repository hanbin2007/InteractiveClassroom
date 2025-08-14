#if os(macOS)
import AppKit
import SwiftUI
import SwiftData

/// Displays the initial course and lesson selection window.
final class CourseSelectionWindowController: NSObject, NSWindowDelegate {
    static let shared = CourseSelectionWindowController()
    private var window: NSWindow?

    func show(container: ModelContainer, connectionManager: PeerConnectionManager) {
        if window == nil {
            let contentView = CourseSelectionView()
                .environmentObject(connectionManager)
                .modelContainer(container)
            let hosting = NSHostingView(rootView: contentView)
            let win = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 400, height: 250),
                               styleMask: [.titled, .closable, .resizable],
                               backing: .buffered,
                               defer: false)
            win.titleVisibility = .visible
            win.toolbar = NSToolbar()
            win.toolbarStyle = .unified
            win.center()
            win.contentView = hosting
            win.isReleasedWhenClosed = false
            win.delegate = self
            window = win
        }
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func close() {
        window?.close()
        window = nil
    }

    func windowWillClose(_ notification: Notification) {
        window = nil
    }
}
#endif
