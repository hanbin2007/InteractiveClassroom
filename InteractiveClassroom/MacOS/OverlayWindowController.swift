#if os(macOS)
import AppKit
import SwiftUI

/// Manages a transparent overlay window that floats above all other apps.
final class OverlayWindowController {
    static let shared = OverlayWindowController()
    private var window: TransparentOverlayWindow?

    /// Shows the overlay window, creating it if necessary.
    func show() {
        if window == nil {
            createWindow()
        }
        window?.orderFront(nil)
    }

    private func createWindow() {
        let frame = NSScreen.main?.frame ?? .zero
        let panel = TransparentOverlayWindow(contentRect: frame)
        panel.contentView = NSHostingView(rootView: ScreenOverlayView())
        panel.orderFrontRegardless()
        window = panel
    }
}

/// A borderless panel configured to behave as a transparent screen overlay.
final class TransparentOverlayWindow: NSPanel {
    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }

    init(contentRect: NSRect) {
        super.init(contentRect: contentRect, styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
        isOpaque = false
        backgroundColor = .clear
        hasShadow = false
        ignoresMouseEvents = true
        level = .screenSaver
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
    }
}

/// Application delegate that defers overlay presentation until explicitly requested.
final class OverlayAppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // The overlay is shown only after the teacher starts the class.
    }
}
#endif
