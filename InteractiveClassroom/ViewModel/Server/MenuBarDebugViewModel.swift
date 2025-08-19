#if os(macOS)
import Foundation

final class MenuBarDebugViewModel: ObservableObject {
    /// Invokes the rebuild on the provided manager.
    func rebuildMenuBar(using manager: MenuBarExtraManager) {
        manager.rebuildMenuBarExtra()
    }
}
#endif
