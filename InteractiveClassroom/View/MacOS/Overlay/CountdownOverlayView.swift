#if os(macOS) || os(iOS)
import SwiftUI

/// A countdown view showing minutes and seconds with animations.
struct CountdownOverlayView: View {
    @ObservedObject var service: CountdownService
    @State private var isVisible = false
    
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
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .multilineTextAlignment(.center)
        .opacity(isVisible ? 1 : 0)
        .scaleEffect(isVisible ? 1 : 0.9)
        .onAppear {
            withAnimation(.easeInOut(duration: 0.3)) {
                isVisible = true
            }
        }
    }
}
#endif
