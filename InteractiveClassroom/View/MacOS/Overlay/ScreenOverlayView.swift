// swiftlint:disable file_length
#if os(macOS)
import SwiftUI
import AppKit

/// Overlay shown on the big screen during a quiz session.
struct ScreenOverlayView: View {
    @EnvironmentObject private var connectionManager: PeerConnectionManager
    @StateObject private var model = ScreenOverlayModel()

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                if connectionManager.classSummaryActive {
                    ClassSummaryOverlayView()
                        .transition(.opacity)
                } else {
                    OverlayTopBarView(questionType: model.questionType.displayName,
                                      remainingTime: model.remainingTimeString)
                    OverlayStatsView(stats: model.statsDisplay)
                    OverlayNamesView(names: model.submittedNames)
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
        .background(Color.clear)
        .ignoresSafeArea()
        .foregroundStyle(.white)
        .background(WindowConfigurator())
        .animation(.easeInOut, value: connectionManager.classSummaryActive)
        .onAppear {
            if connectionManager.showClassSummary {
                NSApp.presentationOptions.insert(.hideMenuBar)
            }
        }
        .onChange(of: connectionManager.showClassSummary) { show in
            if show {
                NSApp.presentationOptions.insert(.hideMenuBar)
            } else {
                NSApp.presentationOptions.remove(.hideMenuBar)
            }
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
