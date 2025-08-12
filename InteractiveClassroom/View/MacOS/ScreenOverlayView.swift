#if os(macOS)
import SwiftUI

/// Placeholder overlay shown on the big screen during a quiz session.
struct ScreenOverlayView: View {
    var body: some View {
        ZStack {
            Color.black.opacity(0.8)
                .ignoresSafeArea()
            VStack(spacing: 20) {
                Text("Screen Overlay Placeholder")
                    .font(.title)
                    .foregroundStyle(.white)
                Text("Statistics and questions will appear here")
                    .foregroundStyle(.white)
            }
        }
    }
}
#endif
