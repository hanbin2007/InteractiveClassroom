#if os(macOS)
import AppKit

/// NSView that lets mouse events in the menu bar region fall through so that
/// menu bar items remain clickable even when the overlay covers the screen.
final class MenuBarPassthroughView: NSView {
    override func hitTest(_ point: NSPoint) -> NSView? {
        let menuBarHeight = NSStatusBar.system.thickness
        if point.y >= bounds.height - menuBarHeight {
            return nil
        }
        return super.hitTest(point)
    }
}
#endif
