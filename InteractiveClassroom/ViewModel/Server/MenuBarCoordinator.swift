#if os(macOS)
import SwiftUI

/// Coordinates rebuilding of the Menu Bar Extra.
@MainActor
final class MenuBarCoordinator: ObservableObject {
    /// Controls whether the menu bar extra is currently displayed.
    @Published private(set) var isPresented = true

    /// Removes and recreates the menu bar extra.
    func rebuildMenuBar() {
        isPresented = false
        DispatchQueue.main.async { [weak self] in
            self?.isPresented = true
        }
    }
}
#endif
