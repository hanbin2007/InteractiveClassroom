#if os(macOS)
import SwiftUI

/// Manages the lifecycle of the menu bar extra, allowing it to be removed and rebuilt on demand.
@MainActor
final class MenuBarManager: ObservableObject {
    /// Unique identifier used to force `MenuBarExtra` reconstruction.
    @Published private(set) var menuBarID: UUID? = UUID()

    /// Removes the current menu bar extra and recreates it on the next run loop.
    func rebuildMenuBar() {
        menuBarID = nil
        DispatchQueue.main.async {
            self.menuBarID = UUID()
        }
    }
}
#endif
