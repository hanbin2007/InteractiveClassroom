#if os(macOS)
@preconcurrency import SwiftUI
import AppKit
import Combine

/// Handles presentation of the full-screen overlay window.
@MainActor
final class OverlayWindowManager: ObservableObject {
    private let pairingService: PairingService
    private let courseSessionService: CourseSessionService
    private let interactionService: InteractionService
    private let menuBarCoordinator: MenuBarCoordinator

    private var overlayWindow: NSWindow?
    private var originalPresentationOptions: NSApplication.PresentationOptions = []
    private var cancellables: Set<AnyCancellable> = []
    private var pendingRestoreWorkItem: DispatchWorkItem?
    /// One-shot cancellable used by performAfterMenuClosed to avoid token capture warnings.
    private var menuEndTrackingOnce: AnyCancellable?

    init(
        pairingService: PairingService,
        courseSessionService: CourseSessionService,
        interactionService: InteractionService,
        menuBarCoordinator: MenuBarCoordinator
    ) {
        self.pairingService = pairingService
        self.courseSessionService = courseSessionService
        self.interactionService = interactionService
        self.menuBarCoordinator = menuBarCoordinator

        pairingService.$teacherCode
            .receive(on: RunLoop.main)
            .sink { [weak self] code in
                guard let self else { return }
                if code != nil {
                    self.openOverlay()
                } else {
                    self.closeOverlay()
                }
            }
            .store(in: &cancellables)
    }

    /// Presents the overlay configured for full-screen display.
    private func openOverlay() {
        // 不恢复 presentationOptions，避免与下面的设置竞态
        closeOverlay(restorePresentation: false)

        performAfterMenuClosed { [weak self] in
            guard let self else { return }

            // 彻底取消任何还在排队的恢复任务
            self.pendingRestoreWorkItem?.cancel()
            self.pendingRestoreWorkItem = nil

            // 现在安全地切换到 Presentation Mode
            self.originalPresentationOptions = NSApp.presentationOptions
            let target = self.originalPresentationOptions.union([.autoHideDock, .autoHideMenuBar])
            if NSApp.presentationOptions != target {
                NSApp.presentationOptions = target
            }

            let controller = NSHostingController(
                rootView: ScreenOverlayView()
                    .environmentObject(self.pairingService)
                    .environmentObject(self.courseSessionService)
                    .environmentObject(self.interactionService)
                    .environmentObject(self)
                    .environmentObject(self.menuBarCoordinator)
            )
            let window = NSWindow(contentViewController: controller)
            self.configureOverlayWindow(window)
            window.orderFrontRegardless()
            self.overlayWindow = window
        }
    }

    /// Closes any visible overlay windows and restores the application's presentation options.
    func closeOverlay(restorePresentation: Bool = true) {
        // 关掉现有 overlay 窗口
        if let window = overlayWindow {
            window.orderOut(nil)
            window.close()
        }
        NSApp.windows
            .filter { $0.identifier?.rawValue == "overlay" && $0.isVisible }
            .forEach { $0.orderOut(nil); $0.close() }
        overlayWindow = nil

        // 取消任何已排队的恢复任务（避免与即将 open 的设置打架）
        pendingRestoreWorkItem?.cancel()
        pendingRestoreWorkItem = nil

        if restorePresentation {
            // 稍后再恢复，避开可能仍在结束的菜单跟踪
            let work = DispatchWorkItem { [originalPresentationOptions] in
                NSApp.presentationOptions = originalPresentationOptions
            }
            pendingRestoreWorkItem = work
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05, execute: work)
        }

        NSApp.activate(ignoringOtherApps: true)
        #if DEBUG
        assert(NSApp.windows.allSatisfy { !($0.identifier?.rawValue == "overlay" && $0.isVisible) }, "Overlay window should be closed")
        #endif
    }

    /// Applies identifier and screen configuration to the overlay window.
    private func configureOverlayWindow(_ window: NSWindow) {
        window.identifier = NSUserInterfaceItemIdentifier("overlay")
        window.level = NSWindow.Level(rawValue: NSWindow.Level.mainMenu.rawValue - 1)
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        if let screenFrame = NSScreen.main?.frame {
            window.setFrame(screenFrame, display: true)
            window.contentView?.frame = screenFrame
        }
        window.styleMask = [.borderless]
        window.isOpaque = false
        window.backgroundColor = .clear
        // Avoid double free crashes by keeping the window alive until we
        // explicitly release our reference.
        window.isReleasedWhenClosed = false
    }
    
    /// Executes work after any active NSMenu tracking has ended, then waits one frame.
    /// Executes work after any active NSMenu tracking has ended, then waits one frame.
    /// Executes work after any active NSMenu tracking has ended, then waits one frame.
    private func performAfterMenuClosed(_ work: @escaping () -> Void) {
        let nc = NotificationCenter.default
        // One-shot using Combine; avoids token capture in @Sendable closures.
        menuEndTrackingOnce = nc.publisher(for: NSMenu.didEndTrackingNotification)
            .first()
            .sink { [weak self] _ in
                guard let self else { return }
                self.menuEndTrackingOnce = nil
                // Give AppKit a beat to rebuild the status bar.
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15, execute: work)
            }
        // Fallback: if no menu is tracking, run on the next turn and cancel the subscriber to avoid duplicates.
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            if let c = self.menuEndTrackingOnce {
                c.cancel()
                self.menuEndTrackingOnce = nil
                DispatchQueue.main.async(execute: work)
            }
        }
    }
}
#endif
