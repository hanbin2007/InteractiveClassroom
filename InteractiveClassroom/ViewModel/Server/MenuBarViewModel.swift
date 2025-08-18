#if os(macOS)
import SwiftUI
import AppKit

/// Handles macOS menu bar window interactions.
@MainActor
final class MenuBarViewModel: ObservableObject {
    /// Token used to force the menu bar view to refresh when changed.
    @Published var reloadToken = UUID()

    /// Opens a window identified by `id` if one isn't already visible.
    /// If the window exists, it is brought to the front instead of creating a duplicate.
    func openWindowIfNeeded(id: String, openWindow: OpenWindowAction) {
        if let window = NSApp.windows.first(where: { $0.identifier?.rawValue == id }) {
            window.makeKeyAndOrderFront(nil)
        } else {
            openWindow(id: id)
        }
    }

    /// Generates a new reload token causing any view referencing it to rebuild.
    func reloadMenuBar() {
        reloadToken = UUID()
    }
}
#endif
