import Foundation
#if os(macOS)
import AppKit

/// Manages application windows and focus on macOS.
struct ApplicationWindowManager {
    /// Hide app windows (non-overlay) and bring overlay to front without stealing focus.
    static func closeAllWindowsAndFocus() {
        // ① 隐藏（不要 close）
        for window in NSApp.windows where window.identifier?.rawValue != "overlay" {
            window.orderOut(nil)
        }
        // ② 只前置，不做 key；并确保 overlay 不接收输入
        if let overlay = NSApp.windows.first(where: { $0.identifier?.rawValue == "overlay" }) {
            overlay.makeFirstResponder(nil)        // 不占键盘焦点
            overlay.orderFrontRegardless()         // 不用 makeKeyAndOrderFront
        }
        // ③ 如需前置 App，可在菜单关闭后前置，避免与菜单时序相撞
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            NSApp.activate(ignoringOtherApps: true)
        }
    }
}
#else
/// Stub implementation for platforms without multi-window management.
struct ApplicationWindowManager {
    static func closeAllWindowsAndFocus() {}
}
#endif
