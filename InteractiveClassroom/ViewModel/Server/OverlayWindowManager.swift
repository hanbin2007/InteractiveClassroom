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
    }

    /// Presents the overlay configured for full-screen display.
    private func openOverlay() {
        closeOverlay()
        originalPresentationOptions = NSApp.presentationOptions
        NSApp.presentationOptions = originalPresentationOptions.union([.autoHideDock, .autoHideMenuBar])
        let controller = NSHostingController(
            rootView: ScreenOverlayView()
                .environmentObject(pairingService)
                .environmentObject(courseSessionService)
                .environmentObject(interactionService)
                .environmentObject(self)
        )
        let window = NSWindow(contentViewController: controller)
        configureOverlayWindow(window)
        window.orderFrontRegardless()
        overlayWindow = window
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
        showCourseSelectionWindow()
        NSApp.activate(ignoringOtherApps: true)
        #if DEBUG
        // Assert that no overlay windows remain visible after teardown.
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

    /// Brings the course-selection window to the front, creating it if necessary.
    private func showCourseSelectionWindow() {
        if let window = NSApp.windows.first(where: { $0.identifier?.rawValue == "courseSelection" }) {
            window.makeKeyAndOrderFront(nil)
            return
        }

        let controller = NSHostingController(
            rootView: CourseSelectionView(
                viewModel: OpenClassroomViewModel(
                    courseSessionService: courseSessionService,
                    pairingService: pairingService
                )
            )
            .environmentObject(courseSessionService)
            .environmentObject(pairingService)
        )
        let window = NSWindow(contentViewController: controller)
        window.identifier = NSUserInterfaceItemIdentifier("courseSelection")
        window.makeKeyAndOrderFront(nil as Any?)
    }
}
#endif
