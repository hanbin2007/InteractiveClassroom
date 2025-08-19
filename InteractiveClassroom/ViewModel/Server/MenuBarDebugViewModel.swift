#if os(macOS)
import SwiftUI

/// View model powering the debug interface for menu bar operations.
@MainActor
final class MenuBarDebugViewModel: ObservableObject {
    private let coordinator: MenuBarCoordinator

    init(coordinator: MenuBarCoordinator) {
        self.coordinator = coordinator
    }

    /// Rebuilds the menu bar extra.
    func rebuildMenuBar() {
        coordinator.rebuildMenuBar()
    }
}
#endif
