#if os(macOS)
import SwiftUI

/// Debug view providing a button to rebuild the menu bar extra.
struct MenuBarDebugView: View {
    @StateObject private var viewModel: MenuBarDebugViewModel

    init(menuBarManager: MenuBarManager) {
        _viewModel = StateObject(wrappedValue: MenuBarDebugViewModel(menuBarManager: menuBarManager))
    }

    var body: some View {
        VStack {
            Button("Rebuild Menu Bar") {
                viewModel.rebuildMenuBar()
            }
            .padding()
        }
        .frame(minWidth: 200, minHeight: 100)
    }
}
#endif
