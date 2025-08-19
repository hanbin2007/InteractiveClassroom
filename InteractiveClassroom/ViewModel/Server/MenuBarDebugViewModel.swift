#if os(macOS)
import Foundation

/// ViewModel for debugging menu bar reconstruction.
@MainActor
final class MenuBarDebugViewModel: ObservableObject {
    private let menuBarManager: MenuBarManager

    init(menuBarManager: MenuBarManager) {
        self.menuBarManager = menuBarManager
    }

    /// Triggers a menu bar rebuild via `MenuBarManager`.
    func rebuildMenuBar() {
        menuBarManager.rebuildMenuBar()
    }
}
#endif
