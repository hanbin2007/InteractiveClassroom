#if os(macOS) || os(iOS)
import SwiftUI

/// A countdown view showing minutes and seconds with animations.
struct CountdownOverlayView: View {
    @ObservedObject var service: CountdownService
    @AppStorage("overlayContentScale") private var overlayContentScale: Double = 1.0
    
    @ViewBuilder
    private var countdownText: some View {
        CountdownDigitsView(remainingSeconds: service.remainingSeconds)
    }

    var body: some View {
        VStack(spacing: 24) {
            Text("Class Starts In")
                .font(.title)
                .bold()
                .foregroundColor(.white)
            countdownText
        }
        .scaleEffect(overlayContentScale)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .multilineTextAlignment(.center)
    }
}
#endif
