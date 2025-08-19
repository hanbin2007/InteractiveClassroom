#if os(macOS)
import Foundation
import SwiftUI

@MainActor
final class MenuBarExtraManager: ObservableObject {
    @Published private(set) var menuBarExtraID = UUID()

    /// Removes and recreates the menu bar extra by changing its identity.
    func rebuildMenuBarExtra() {
        menuBarExtraID = UUID()
    }
}
#endif
