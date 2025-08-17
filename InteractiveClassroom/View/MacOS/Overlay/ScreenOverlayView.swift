#if os(macOS) || os(iOS)
import SwiftUI
#if os(macOS)
import AppKit
import CoreGraphics
#endif

/// Full-screen overlay container responsible for presenting interactive content.
struct ScreenOverlayView: View {
    @EnvironmentObject private var connectionManager: PeerConnectionManager
    @Environment(\.openWindow) private var openWindow
    @State private var isToolbarFolded = false

    #if os(macOS)
    /// Opens or brings to front the window identified by `id`.
    private func openWindowIfNeeded(id: String) {
        if let window = NSApp.windows.first(where: { $0.identifier?.rawValue == id }) {
            window.makeKeyAndOrderFront(nil)
        } else {
            openWindow(id: id)
        }
    }
    #else
    /// Opens a new window scene for the given identifier.
    private func openWindowIfNeeded(id: String) {
        openWindow(id: id)
    }
    #endif

    private func endCurrentClass() {
        connectionManager.endClass()
        connectionManager.currentCourse = nil
        connectionManager.currentLesson = nil
    }

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
                Spacer()
                HStack {
                    Spacer()
                    HStack(spacing: 12) {
                        HStack(spacing: 12) {
                            if connectionManager.teacherCode != nil {
                                Button {
                                    endCurrentClass()
                                } label: {
                                    Image(systemName: "xmark.circle")
                                        .frame(width: 24, height: 24)
                                        .padding(10)
                                        .background(.ultraThinMaterial)
                                        .clipShape(Circle())
                                        .accessibilityLabel("End Class")
                                }
                                .buttonStyle(.plain)
                                .frame(width: 44, height: 44)
                            }

                            Button {
                                openWindowIfNeeded(id: "clients")
                            } label: {
                                Image(systemName: "person.2")
                                    .frame(width: 24, height: 24)
                                    .padding(10)
                                    .background(.ultraThinMaterial)
                                    .clipShape(Circle())
                                    .accessibilityLabel("Clients")
                            }
                            .buttonStyle(.plain)
                            .frame(width: 44, height: 44)

                            Button {
                                openWindowIfNeeded(id: "courseManager")
                            } label: {
                                Image(systemName: "book")
                                    .frame(width: 24, height: 24)
                                    .padding(10)
                                    .background(.ultraThinMaterial)
                                    .clipShape(Circle())
                                    .accessibilityLabel("Courses")
                            }
                            .buttonStyle(.plain)
                            .frame(width: 44, height: 44)

                            #if os(macOS)
                            if #available(macOS 13, *) {
                                SettingsLink {
                                    Image(systemName: "gearshape")
                                        .frame(width: 24, height: 24)
                                        .padding(10)
                                        .background(.ultraThinMaterial)
                                        .clipShape(Circle())
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel("Settings")
                                .frame(width: 44, height: 44)
                            } else {
                                Button {
                                    NSApp.sendAction(Selector(("showPreferencesWindow:")), to: nil, from: nil)
                                } label: {
                                    Image(systemName: "gearshape")
                                        .frame(width: 24, height: 24)
                                        .padding(10)
                                        .background(.ultraThinMaterial)
                                        .clipShape(Circle())
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel("Settings")
                                .frame(width: 44, height: 44)
                            }

                            Button {
                                NSApp.terminate(nil)
                            } label: {
                                Image(systemName: "power")
                                    .frame(width: 24, height: 24)
                                    .padding(10)
                                    .background(.ultraThinMaterial)
                                    .clipShape(Circle())
                                    .accessibilityLabel("Quit")
                            }
                            .buttonStyle(.plain)
                            .frame(width: 44, height: 44)
                            #endif
                        }
                        .frame(height: 44)
                        .frame(width: isToolbarFolded ? 0 : nil)
                        .clipped()
                        .opacity(isToolbarFolded ? 0 : 1)
                        .allowsHitTesting(!isToolbarFolded)
                        .animation(.easeInOut(duration: 0.25), value: isToolbarFolded)

                        Button {
                            withAnimation(.easeInOut(duration: 0.25)) {
                                isToolbarFolded.toggle()
                            }
                        } label: {
                            Image(systemName: isToolbarFolded ? "chevron.left" : "chevron.right")
                                .frame(width: 24, height: 24)
                                .padding(10)
                                .background(.ultraThinMaterial)
                                .clipShape(Circle())
                        }
                        .buttonStyle(.plain)
                        .frame(width: 44, height: 44)
                        .accessibilityLabel(isToolbarFolded ? "Expand Toolbar" : "Fold Toolbar")

                        Button {
                            connectionManager.toggleOverlayContentVisibility()
                        } label: {
                            Image(systemName: connectionManager.isOverlayContentVisible ? "eye.slash" : "eye")
                                .frame(width: 24, height: 24)
                                .padding(10)
                                .background(.ultraThinMaterial)
                                .clipShape(Circle())
                        }
                        .buttonStyle(.plain)
                        .frame(width: 44, height: 44)
                        .accessibilityLabel("Toggle Overlay")
                    }
                    .padding()
                }
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
