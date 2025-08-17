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
                        if !isToolbarFolded {
                            Group {
                                if connectionManager.teacherCode != nil {
                                    Button {
                                        endCurrentClass()
                                    } label: {
                                        Image(systemName: "xmark.circle")
                                            .padding(10)
                                            .background(.ultraThinMaterial)
                                            .clipShape(Circle())
                                            .accessibilityLabel("End Class")
                                    }
                                }

                                Button {
                                    openWindowIfNeeded(id: "clients")
                                } label: {
                                    Image(systemName: "person.2")
                                        .padding(10)
                                        .background(.ultraThinMaterial)
                                        .clipShape(Circle())
                                        .accessibilityLabel("Clients")
                                }

                                Button {
                                    openWindowIfNeeded(id: "courseManager")
                                } label: {
                                    Image(systemName: "book")
                                        .padding(10)
                                        .background(.ultraThinMaterial)
                                        .clipShape(Circle())
                                        .accessibilityLabel("Courses")
                                }

                                #if os(macOS)
                                if #available(macOS 13, *) {
                                    SettingsLink {
                                        Image(systemName: "gearshape")
                                            .padding(10)
                                            .background(.ultraThinMaterial)
                                            .clipShape(Circle())
                                    }
                                    .buttonStyle(.plain)
                                    .accessibilityLabel("Settings")
                                } else {
                                    Button {
                                        NSApp.sendAction(Selector(("showPreferencesWindow:")), to: nil, from: nil)
                                    } label: {
                                        Image(systemName: "gearshape")
                                            .padding(10)
                                            .background(.ultraThinMaterial)
                                            .clipShape(Circle())
                                    }
                                    .accessibilityLabel("Settings")
                                }

                                Button {
                                    NSApp.terminate(nil)
                                } label: {
                                    Image(systemName: "power")
                                        .padding(10)
                                        .background(.ultraThinMaterial)
                                        .clipShape(Circle())
                                        .accessibilityLabel("Quit")
                                }
                                #endif
                            }
                            .transition(.move(edge: .trailing).combined(with: .opacity))
                        }

                        Button {
                            withAnimation(.easeInOut) {
                                isToolbarFolded.toggle()
                            }
                        } label: {
                            Image(systemName: isToolbarFolded ? "chevron.left" : "chevron.right")
                                .padding(10)
                                .background(.ultraThinMaterial)
                                .clipShape(Circle())
                                .accessibilityLabel(isToolbarFolded ? "Expand Toolbar" : "Fold Toolbar")
                        }

                        Button {
                            connectionManager.toggleOverlayContentVisibility()
                        } label: {
                            Image(systemName: connectionManager.isOverlayContentVisible ? "eye.slash" : "eye")
                                .padding(10)
                                .background(.ultraThinMaterial)
                                .clipShape(Circle())
                                .accessibilityLabel("Toggle Overlay")
                        }
                    }
                    .padding()
                    .animation(.easeInOut, value: isToolbarFolded)
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
