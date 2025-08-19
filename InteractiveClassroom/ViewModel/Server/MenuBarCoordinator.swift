#if os(macOS)
import SwiftUI

/// Coordinates rebuilding of the Menu Bar Extra.
@MainActor
final class MenuBarCoordinator: ObservableObject {
    /// Identifier used to force SwiftUI to recreate the menu bar extra.
    @Published private(set) var refreshID = UUID()

    /// Removes and recreates the menu bar extra.
    func rebuildMenuBar() {
        refreshID = UUID()
    }
}
#endif
