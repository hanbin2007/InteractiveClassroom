#if os(macOS)
import SwiftUI

/// Debugging view with a button to rebuild the menu bar.
struct MenuBarDebugView: View {
    @EnvironmentObject private var menuBarController: MenuBarExtraController
    @StateObject private var viewModel = MenuBarDebugViewModel()

    var body: some View {
        VStack {
            Button("Rebuild Menu Bar") {
                DispatchQueue.main.async {
                    viewModel.rebuildMenuBar(using: menuBarController)
                }
            }
            .padding()
        }
        .frame(minWidth: 200, minHeight: 80)
    }
}

#Preview {
    let controller = MenuBarExtraController()
    MenuBarDebugView()
        .environmentObject(controller)
}
#endif
