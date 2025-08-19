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

    private var overlayWindow: NSWindow?
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
            self.originalPresentationOptions = NSApp.presentationOptions
            // Delay changing presentation options so active menus can close without being reset mid-interaction.
            NSApp.presentationOptions = self.originalPresentationOptions.union([.autoHideDock, .autoHideMenuBar])

            let controller = NSHostingController(
                rootView: ScreenOverlayView()
                    .environmentObject(self.pairingService)
                    .environmentObject(self.courseSessionService)
                    .environmentObject(self.interactionService)
                    .environmentObject(self)
            )
            let window = NSWindow(contentViewController: controller)
            self.configureOverlayWindow(window)
            window.orderFrontRegardless()
            self.overlayWindow = window
        }

        DispatchQueue.main.async {
            if let event = NSApp.currentEvent,
               [.leftMouseDown, .leftMouseUp, .keyDown].contains(event.type) {
                // A menu interaction is likely in progress; retry after a short delay.
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2, execute: presentOverlay)
            } else {
                presentOverlay()
            }
        }
    }

    /// Closes any visible overlay windows and restores the application's presentation options.
    func closeOverlay() {
        // Close the tracked overlay window first.
        if let window = overlayWindow {
            window.orderOut(nil)
            window.close()
        }

        // Catch any additional overlay windows that might have been created elsewhere.
        NSApp.windows
            .filter { $0.identifier?.rawValue == "overlay" && $0.isVisible }
            .forEach { window in
                window.orderOut(nil)
                window.close()
            }

        overlayWindow = nil
        NSApp.presentationOptions = originalPresentationOptions
        NSApp.activate(ignoringOtherApps: true)
        #if DEBUG
        // Assert that no overlay windows remain visible after teardown.
        assert(NSApp.windows.allSatisfy { !($0.identifier?.rawValue == "overlay" && $0.isVisible) }, "Overlay window should be closed")
        #endif
    }

    /// Applies identifier and screen configuration to the overlay window.
    private func configureOverlayWindow(_ window: NSWindow) {
        window.identifier = NSUserInterfaceItemIdentifier("overlay")
        // Ensure the overlay appears above the menu bar and full-screen windows.
        window.level = .screenSaver
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
}
#endif
