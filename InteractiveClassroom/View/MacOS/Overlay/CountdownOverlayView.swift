#if os(macOS) || os(iOS)
import SwiftUI

/// A countdown view showing minutes and seconds with animations.
struct CountdownOverlayView: View {
    @ObservedObject var service: CountdownService
    @AppStorage("overlayContentScale") private var overlayContentScale: Double = 1.0
    @ScaledMetric private var baseSpacing: CGFloat = 24
    @ScaledMetric private var baseTitleSize: CGFloat = 34
    
    @ViewBuilder
    private var countdownText: some View {
        CountdownDigitsView(remainingSeconds: service.remainingSeconds)
    }

    var body: some View {
        VStack(spacing: baseSpacing * overlayContentScale) {
            Text("Class Starts In")
                .font(.system(size: baseTitleSize * overlayContentScale, weight: .bold))
                .foregroundColor(.white)
            countdownText
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .multilineTextAlignment(.center)
    }
}
#endif
