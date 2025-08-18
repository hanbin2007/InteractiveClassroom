#if os(macOS)
import SwiftUI
import AppKit

/// Handles macOS menu bar window management.
@MainActor
final class MenuBarViewModel: ObservableObject {
    private var overlayWindow: NSWindow?
    private var originalPresentationOptions: NSApplication.PresentationOptions = []

    /// Presents the full-screen overlay window.
    func openOverlay(
        pairingService: PairingService,
        courseSessionService: CourseSessionService,
        interactionService: InteractionService
    ) {
        closeOverlay()
        originalPresentationOptions = NSApp.presentationOptions
        NSApp.presentationOptions = originalPresentationOptions.union([.autoHideDock, .autoHideMenuBar])
        let controller = NSHostingController(
            rootView: ScreenOverlayView()
                .environmentObject(pairingService)
                .environmentObject(courseSessionService)
                .environmentObject(interactionService)
        )
        let window = NSWindow(contentViewController: controller)
        window.isReleasedWhenClosed = false
        window.makeKeyAndOrderFront(nil)
        overlayWindow = window
    }

    /// Closes any existing overlay windows and restores normal presentation.
    func closeOverlay() {
        overlayWindow?.close()
        overlayWindow = nil
        NSApp.windows.filter { $0.identifier?.rawValue == "overlay" }.forEach { $0.close() }
        NSApp.presentationOptions = originalPresentationOptions
    }

    /// Opens a window identified by `id` if one isn't already visible.
    /// If the window exists, it is brought to the front instead of creating a duplicate.
    func openWindowIfNeeded(id: String, openWindow: OpenWindowAction) {
        if let window = NSApp.windows.first(where: { $0.identifier?.rawValue == id }) {
            window.makeKeyAndOrderFront(nil)
        } else {
            openWindow(id: id)
        }
    }
}
#endif
