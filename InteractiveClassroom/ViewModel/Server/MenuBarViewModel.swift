#if os(macOS)
import SwiftUI
import AppKit

/// Handles macOS menu bar window interactions.
@MainActor
final class MenuBarViewModel: ObservableObject {
    /// Schedules `action` to run after the current menu tracking cycle ends.
    /// This avoids interfering with the menu's internal event loop when opening
    /// windows or changing application state.
    func runAfterMenuDismissal(_ action: @escaping () -> Void) {
        DispatchQueue.main.async {
            action()
        }
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

    /// Handles the primary classroom action based on pairing state.
    /// - Parameters:
    ///   - pairingService: Current pairing service to inspect for active session.
    ///   - overlayManager: Overlay manager used when ending a class.
    ///   - courseSessionService: Session service controlling class lifecycle.
    ///   - openWindow: Action to present the course selection window.
    func handleClassAction(
        pairingService: PairingService,
        overlayManager: OverlayWindowManager,
        courseSessionService: CourseSessionService,
        openWindow: OpenWindowAction
    ) {
        if pairingService.teacherCode == nil {
            openWindowIfNeeded(id: "courseSelection", openWindow: openWindow)
        } else {
            overlayManager.closeOverlay()
            courseSessionService.endClass()
            openWindowIfNeeded(id: "courseSelection", openWindow: openWindow)
        }
    }
}
#endif
