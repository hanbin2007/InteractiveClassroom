#if os(macOS)
import SwiftUI
import AppKit

/// NSVisualEffectView that ignores all mouse events, allowing clicks to pass through.
private final class PassthroughVisualEffectView: NSVisualEffectView {
    override func hitTest(_ point: NSPoint) -> NSView? { nil }
}

/// A blurred background view that forwards mouse events to views underneath.
struct PassthroughBlurView: NSViewRepresentable {
    var tint: Color

    func makeNSView(context: Context) -> PassthroughVisualEffectView {
        let view = PassthroughVisualEffectView()
        view.state = .active
        view.material = .hudWindow
        view.blendingMode = .behindWindow
        view.wantsLayer = true
        updateTint(for: view)
        return view
    }

    func updateNSView(_ nsView: PassthroughVisualEffectView, context: Context) {
        updateTint(for: nsView)
    }

    private func updateTint(for view: NSVisualEffectView) {
        view.layer?.backgroundColor = NSColor(tint).withAlphaComponent(0.4).cgColor
    }
}
#endif
