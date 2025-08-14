#if os(macOS)
import AppKit
import SwiftUI
import SwiftData

/// Manages a window displaying details for a course.
final class CourseDetailWindowController: NSObject, NSWindowDelegate {
    static let shared = CourseDetailWindowController()
    private var window: NSWindow?

    func show(course: Course, container: ModelContainer) {
        if window == nil {
            let contentView = CourseDetailView(course: course)
                .modelContainer(container)
            let hosting = NSHostingView(rootView: contentView)
            let win = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 400, height: 300),
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

    func windowWillClose(_ notification: Notification) {
        window = nil
    }
}
#endif
