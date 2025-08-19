#if os(macOS)
import SwiftUI

/// Controls visibility of the macOS MenuBarExtra and supports rebuilding.
@MainActor
final class MenuBarExtraController: ObservableObject {
    /// Indicates whether the MenuBarExtra should be displayed.
    @Published var isVisible: Bool = true

    /// Removes and recreates the MenuBarExtra to clear its state.
    ///
    /// Visibility toggles are yielded across run loop iterations to avoid
    /// publishing changes during a view update.
    func rebuild() {
        Task { @MainActor [weak self] in
            self?.isVisible = false
            await Task.yield()
            self?.isVisible = true
        }
    }
}
#endif
