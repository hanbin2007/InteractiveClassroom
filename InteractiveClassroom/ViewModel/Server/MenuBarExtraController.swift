#if os(macOS)
import SwiftUI

/// Controls visibility of the macOS MenuBarExtra and supports rebuilding.
@MainActor
final class MenuBarExtraController: ObservableObject {
    /// Indicates whether the MenuBarExtra should be displayed.
    @Published var isVisible: Bool = true

    /// Removes and recreates the MenuBarExtra to clear its state.
    ///
    /// Visibility is toggled off immediately and restored on the next run
    /// loop to ensure the status item is fully torn down before being
    /// reinserted, avoiding undefined behavior in SwiftUI.
    func rebuild() {
        isVisible = false
        DispatchQueue.main.async { [weak self] in
            self?.isVisible = true
        }
    }
}
#endif
