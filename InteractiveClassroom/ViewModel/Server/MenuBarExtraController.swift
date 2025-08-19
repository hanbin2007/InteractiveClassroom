#if os(macOS)
import SwiftUI

/// Controls visibility of the macOS MenuBarExtra and supports rebuilding.
@MainActor
final class MenuBarExtraController: ObservableObject {
    /// Indicates whether the MenuBarExtra should be displayed.
    @Published var isVisible: Bool = true

    /// Removes and recreates the MenuBarExtra on a later run loop to clear its
    /// state without mutating during an in-progress view update.
    func rebuild() async {
        isVisible = false
        await Task.yield()
        isVisible = true
    }
}
#endif
