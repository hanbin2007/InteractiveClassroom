#if os(macOS)
import Foundation

/// View model for `MenuBarDebugView` providing access to rebuild actions.
@MainActor
final class MenuBarDebugViewModel: ObservableObject {
    func rebuildMenuBar(using controller: MenuBarExtraController) {
        Task { await controller.rebuild() }
    }
}
#endif
