#if os(macOS)
import SwiftUI
import AppKit
import Combine

/// Handles presentation of the full-screen overlay window.
@MainActor
final class OverlayWindowManager: ObservableObject {
    private let pairingService: PairingService
    private let courseSessionService: CourseSessionService
    private let interactionService: InteractionService

    private var overlayWindow: NSPanel?
    private var originalPresentationOptions: NSApplication.PresentationOptions = []
    private var cancellables: Set<AnyCancellable> = []

    init(
        pairingService: PairingService,
        courseSessionService: CourseSessionService,
        interactionService: InteractionService
    ) {
        self.pairingService = pairingService
        self.courseSessionService = courseSessionService
        self.interactionService = interactionService

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

        interactionService.$activeInteraction
            .compactMap { $0 }
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                ApplicationWindowManager.closeAllWindowsAndFocus()
                self?.openOverlay()
            }
            .store(in: &cancellables)
    }

    /// Presents the overlay configured for full-screen display.
    private func openOverlay() {
        closeOverlay()

        let presentOverlay = { [weak self] in
            guard let self else { return }

            let controller = NSHostingController(
                rootView: ScreenOverlayView()
                    .environmentObject(self.pairingService)
                    .environmentObject(self.courseSessionService)
                    .environmentObject(self.interactionService)
                    .environmentObject(self)
            )

            // 使用 NSPanel，避免需要激活应用
            let panel = NSPanel(
                contentRect: NSScreen.main?.frame ?? .zero,
                styleMask: [.borderless, .nonactivatingPanel],
                backing: .buffered,
                defer: false
            )
            panel.contentViewController = controller
            self.configureOverlayWindow(panel)

            // 不要 makeKey，不要 activate
            panel.orderFrontRegardless()
            self.overlayWindow = panel
        }

        DispatchQueue.main.async {
            if let event = NSApp.currentEvent,
               [.leftMouseDown, .leftMouseUp, .keyDown].contains(event.type) {
                // 菜单交互期间，稍后再尝试
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2, execute: presentOverlay)
            } else {
                presentOverlay()
            }
        }
    }

    /// Closes any visible overlay windows and restores the application's presentation options.
    func closeOverlay() {
        if let window = overlayWindow {
            window.orderOut(nil)
            window.close()
        }

        NSApp.windows
            .filter { $0.identifier?.rawValue == "overlay" && $0.isVisible }
            .forEach { window in
                window.orderOut(nil)
                window.close()
            }

        overlayWindow = nil
        NSApp.presentationOptions = originalPresentationOptions

        #if DEBUG
        assert(NSApp.windows.allSatisfy { !($0.identifier?.rawValue == "overlay" && $0.isVisible) },
               "Overlay window should be closed")
        #endif
    }

    /// Applies identifier and screen configuration to the overlay window.
    private func configureOverlayWindow(_ window: NSWindow) {
        window.identifier = NSUserInterfaceItemIdentifier("overlay")
        window.level = .screenSaver
        window.collectionBehavior = [.canJoinAllSpaces]

        if let screenFrame = NSScreen.main?.frame {
            window.setFrame(screenFrame, display: true)
            window.contentView?.frame = screenFrame
        }

        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = false
        window.hidesOnDeactivate = false
        window.isReleasedWhenClosed = false
    }
}
#endif
