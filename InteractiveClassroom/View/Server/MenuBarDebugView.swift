#if os(macOS) && DEBUG
import SwiftUI

/// Debug view providing manual controls for menu bar rebuilding.
struct MenuBarDebugView: View {
    @StateObject private var viewModel: MenuBarDebugViewModel

    init(coordinator: MenuBarCoordinator) {
        _viewModel = StateObject(wrappedValue: MenuBarDebugViewModel(coordinator: coordinator))
    }

    var body: some View {
        VStack {
            Button("Rebuild Menu Bar") {
                viewModel.rebuildMenuBar()
            }
            .padding()
        }
    }
}

#Preview {
    MenuBarDebugView(coordinator: MenuBarCoordinator())
}
#endif
