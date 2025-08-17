import Foundation
#if os(macOS)
import AppKit

/// Manages application windows and focus on macOS.
struct ApplicationWindowManager {
    /// Closes all application windows except the overlay and brings the app to the front.
    static func closeAllWindowsAndFocus() {
        // Close all non-overlay windows.
        for window in NSApp.windows where window.identifier?.rawValue != "overlay" {
            window.close()
        }
        // Ensure the overlay remains key and the app is active.
        if let overlay = NSApp.windows.first(where: { $0.identifier?.rawValue == "overlay" }) {
            overlay.makeKeyAndOrderFront(nil)
        }
        NSApp.activate(ignoringOtherApps: true)
    }
}
#else
/// Stub implementation for platforms without multi-window management.
struct ApplicationWindowManager {
    static func closeAllWindowsAndFocus() {}
}
#endif
