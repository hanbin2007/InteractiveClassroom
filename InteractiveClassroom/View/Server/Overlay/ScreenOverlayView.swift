#if os(macOS) || os(iOS)
import SwiftUI
#if os(macOS)
import AppKit
import CoreGraphics
#endif

/// Full-screen overlay container responsible for presenting interactive content.
struct ScreenOverlayView: View {
    @EnvironmentObject private var pairingService: PairingService
    @EnvironmentObject private var courseSessionService: CourseSessionService
    @EnvironmentObject private var interactionService: InteractionService
    @Environment(\.openWindow) private var openWindow
    @State private var isToolbarFolded = false
    #if os(macOS)
    @EnvironmentObject private var overlayManager: OverlayWindowManager
    #endif

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
        #if os(macOS)
        overlayManager.closeOverlay()
        #endif
        courseSessionService.endClass()
    }

    var body: some View {
        ZStack {
            if let content = interactionService.overlayContent {
                Group {
                    switch content.template {
                    case .fullScreen(let color):
                        FullScreenOverlay(
                            background: color,
                            isVisible: interactionService.isOverlayContentVisible
                        ) {
                            content.view
                        }
                    case .floatingCorner(let position):
                        CornerOverlay(
                            corner: position,
                            isVisible: interactionService.isOverlayContentVisible
                        ) {
                            content.view
                        }
                    }
                }
            }
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    HStack(spacing: 12) {
                        HStack(spacing: 12) {
                            if pairingService.teacherCode != nil {
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
                            interactionService.toggleOverlayVisibility()
                        } label: {
                            Image(systemName: interactionService.isOverlayContentVisible ? "eye.slash" : "eye")
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
            .zIndex(1) // Ensure toolbar remains above overlay content
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.clear)
        .ignoresSafeArea(.all)
    }
}


/// Template providing a blurred color full-screen background.
struct FullScreenOverlay<Content: View>: View {
    var background: Color
    var isVisible: Bool
    @ViewBuilder var content: () -> Content

    var body: some View {
        ZStack {
            if isVisible {
#if os(macOS)
                PassthroughBlurView(tint: background)
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
                    .transition(.opacity)
#else
                Rectangle()
                    .fill(background.opacity(0.4))
                    .background(.ultraThinMaterial)
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
                    .transition(.opacity)
#endif
            }

            if isVisible {
                content()
                    .transition(
                        .scale(scale: 0.9, anchor: .center)
                            .combined(with: .opacity)
                    )
            }
        }
    }
}

/// Template anchoring content to a screen corner without a background.
struct CornerOverlay<Content: View>: View {
    var corner: OverlayCorner
    var isVisible: Bool
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
            if isVisible {
                content()
                    .padding()
                    .transition(
                        .scale(scale: 0.9, anchor: .center)
                            .combined(with: .opacity)
                    )
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea()
    }
}

#endif
