#if os(macOS)
import SwiftUI

/// Controls visibility of the macOS MenuBarExtra and supports rebuilding.
@MainActor
final class MenuBarExtraController: ObservableObject {
    /// Indicates whether the MenuBarExtra should be displayed.
    @Published var isVisible: Bool = true

    /// Removes and recreates the MenuBarExtra to clear its state without
    /// mutating published properties during the current view update cycle.
    func rebuild() {
        Task { @MainActor [weak self] in
            self?.isVisible = false
            // Yield to the run loop so the removal completes before reinsertion.
            await Task.yield()
            self?.isVisible = true
        }
    }
}
#endif
