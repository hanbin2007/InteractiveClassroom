#if os(macOS)
import SwiftUI

/// Controls visibility of the macOS MenuBarExtra and supports rebuilding.
@MainActor
final class MenuBarExtraController: ObservableObject {
    /// Indicates whether the MenuBarExtra should be displayed.
    @Published var isVisible: Bool = true

    /// Removes and recreates the MenuBarExtra to clear its state.
    ///
    /// State mutations are dispatched asynchronously to avoid publishing
    /// changes during an ongoing view update, which can lead to undefined
    /// behavior in SwiftUI.
    func rebuild() {
        DispatchQueue.main.async { [weak self] in
            self?.isVisible = false
            DispatchQueue.main.async { [weak self] in
                self?.isVisible = true
            }
        }
    }
}
#endif
