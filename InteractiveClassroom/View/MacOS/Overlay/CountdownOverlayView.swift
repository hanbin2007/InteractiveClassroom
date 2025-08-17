#if os(macOS) || os(iOS)
import SwiftUI

/// A countdown view showing minutes and seconds with animations.
struct CountdownOverlayView: View {
    @ObservedObject var service: CountdownService
    
    @ViewBuilder
    private var countdownText: some View {
        CountdownDigitsView(remainingSeconds: service.remainingSeconds)
    }

    var body: some View {
        VStack(spacing: 24) {
            Text("Class Starts In")
                .font(.system(size: 60, weight: .bold))
                .bold()
                .foregroundColor(.white)
            countdownText
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .multilineTextAlignment(.center)
    }
}
#endif
