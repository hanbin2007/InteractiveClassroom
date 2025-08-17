// swiftlint:disable file_length
#if os(macOS)
import SwiftUI
import AppKit

/// Overlay shown on the big screen during a quiz session.
struct ScreenOverlayView: View {
    @EnvironmentObject private var connectionManager: PeerConnectionManager

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                if let interaction = connectionManager.activeInteraction {
                    if connectionManager.overlayVisible {
                        switch interaction {
                        case .classSummary:
                            ClassSummaryOverlayView()
                                .transition(.opacity)
                        }
                    }

                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Button {
                                withAnimation { connectionManager.toggleInteractionVisibility() }
                            } label: {
                                Image(systemName: connectionManager.overlayVisible ? "eye.slash" : "eye")
                                    .padding(12)
                                    .background(Color.black.opacity(0.4))
                                    .clipShape(Circle())
                            }
                            .buttonStyle(.plain)
                            .padding()
                            .accessibilityLabel(connectionManager.overlayVisible ? "Hide Interaction" : "Show Interaction")
                        }
                    }
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
        .background(Color.clear)
        .ignoresSafeArea()
        .foregroundStyle(.white)
        .background(WindowConfigurator())
        .animation(.easeInOut, value: connectionManager.overlayVisible)
        .onAppear { updateMenuBar() }
        .onChange(of: connectionManager.activeInteraction) { _ in updateMenuBar() }
    }

    private func updateMenuBar() {
        if connectionManager.activeInteraction != nil {
            NSApp.presentationOptions.insert(.hideMenuBar)
        } else {
            NSApp.presentationOptions.remove(.hideMenuBar)
        }
    }
}

/// Helper view to configure the hosting window for a full-screen floating overlay.
private struct WindowConfigurator: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        ConfigurableView()
    }

    func updateNSView(_ nsView: NSView, context: Context) {}

    private final class ConfigurableView: NSView {
        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            guard let window = window else { return }
            window.identifier = NSUserInterfaceItemIdentifier("overlay")
            window.level = .screenSaver
            window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
            if let screenFrame = NSScreen.main?.frame {
                window.setFrame(screenFrame, display: true)
            }
            window.styleMask = [.borderless]
            window.isOpaque = false
            window.backgroundColor = .clear
        }
    }
}

#Preview {
    ScreenOverlayView()
}
#endif
