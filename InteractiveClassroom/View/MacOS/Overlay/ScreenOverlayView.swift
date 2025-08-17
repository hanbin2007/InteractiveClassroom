#if os(macOS) || os(iOS)
import SwiftUI
#if os(macOS)
import AppKit
import CoreGraphics
#endif

/// Full-screen overlay container responsible for presenting interactive content.
struct ScreenOverlayView: View {
    @EnvironmentObject private var connectionManager: PeerConnectionManager

    var body: some View {
        ZStack {
            if let content = connectionManager.overlayContent,
               connectionManager.isOverlayContentVisible {
                switch content.template {
                case .fullScreen(let color):
                    FullScreenOverlay(background: color) {
                        content.view
                    }
                case .floatingCorner(let position):
                    CornerOverlay(corner: position) {
                        content.view
                    }
                }
            }
            VStack {
                HStack {
                    Spacer()
                    Button {
                        connectionManager.toggleOverlayContentVisibility()
                    } label: {
                        Image(systemName: connectionManager.isOverlayContentVisible ? "eye.slash" : "eye")
                            .padding(10)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                    }
                    .padding()
                }
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .ignoresSafeArea()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.clear)
        .ignoresSafeArea(.all)
        #if os(macOS)
        .background(WindowConfigurator())
        #endif
    }
}

#if os(macOS)
/// Helper view configuring the hosting window for a full-screen overlay.
private struct WindowConfigurator: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView { ConfigurableView() }
    func updateNSView(_ nsView: NSView, context: Context) {}

    private final class ConfigurableView: NSView {
        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            guard let window = window else { return }
            window.identifier = NSUserInterfaceItemIdentifier("overlay")
            // Place the overlay below the system menu bar so status items remain
            // interactive while still covering the rest of the screen.
            window.level = .mainMenu
            window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
            if let screenFrame = NSScreen.main?.frame {
                window.setFrame(screenFrame, display: true)
                window.contentView?.frame = screenFrame
            }
            window.styleMask = [.borderless]
            window.isOpaque = false
            window.backgroundColor = .clear
            window.orderFrontRegardless()
        }
    }
}
#endif

/// Template providing a blurred color full-screen background.
struct FullScreenOverlay<Content: View>: View {
    var background: Color
    @ViewBuilder var content: () -> Content

    var body: some View {
        ZStack {
            Rectangle()
                .fill(background.opacity(0.4))
                .background(.ultraThinMaterial)
                .ignoresSafeArea()
            content()
        }
    }
}

/// Template anchoring content to a screen corner without a background.
struct CornerOverlay<Content: View>: View {
    var corner: OverlayCorner
    @ViewBuilder var content: () -> Content

    private var alignment: Alignment {
        switch corner {
        case .topLeft: return .topLeading
        case .topRight: return .topTrailing
        case .bottomLeft: return .bottomLeading
        case .bottomRight: return .bottomTrailing
        }
    }

    var body: some View {
        ZStack(alignment: alignment) {
            content()
                .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea()
    }
}

#endif
