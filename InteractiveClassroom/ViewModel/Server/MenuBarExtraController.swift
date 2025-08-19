#if os(macOS)
import SwiftUI

/// Controls visibility of the macOS MenuBarExtra and supports rebuilding.
@MainActor
final class MenuBarExtraController: ObservableObject {
    /// Indicates whether the MenuBarExtra should be displayed.
    @Published private(set) var isVisible: Bool = true

    /// Removes and recreates the MenuBarExtra to clear its state.
    func rebuild() {
        isVisible = false
        DispatchQueue.main.async { [weak self] in
            self?.isVisible = true
        }
    }
}
#endif
