#if os(macOS)
import AppKit
import SwiftUI
import SwiftData

/// Manages the window for lesson CRUD operations within a course.
final class LessonManagerWindowController: NSObject, NSWindowDelegate {
    static let shared = LessonManagerWindowController()
    private var window: NSWindow?

    func show(for course: Course, container: ModelContainer) {
        if window == nil {
            let contentView = LessonManagerView(course: course)
                .modelContainer(container)
            let hosting = NSHostingView(rootView: contentView)
            let win = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 600, height: 400),
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
