#if os(macOS)
import SwiftUI

/// Simple debug interface providing manual menu bar rebuild.
struct MenuBarDebugView: View {
    @EnvironmentObject private var menuBarManager: MenuBarExtraManager
    @StateObject private var viewModel = MenuBarDebugViewModel()

    var body: some View {
        VStack {
            Button("Rebuild Menu Bar") {
                viewModel.rebuildMenuBar(using: menuBarManager)
            }
            .padding()
        }
        .frame(minWidth: 200, minHeight: 100)
    }
}

#Preview {
    MenuBarDebugView()
        .environmentObject(MenuBarExtraManager())
}
#endif
