#if os(macOS) || os(iOS)
import SwiftUI
import Combine

/// A countdown view showing minutes and seconds with animations.
struct CountdownOverlayView: View {
    @State private var remaining: Int
    @State private var isVisible = false
    @State private var tick = false
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    init(seconds: Int) {
        _remaining = State(initialValue: max(seconds, 0))
    }

    private var formattedTime: String {
        let minutes = remaining / 60
        let seconds = remaining % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    var body: some View {
        VStack(spacing: 24) {
            Text("Class Starts In")
                .font(.title)
                .foregroundColor(.white)
            Text(formattedTime)
                .font(.system(size: 120, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .monospacedDigit()
                .scaleEffect(tick ? 1.1 : 1.0)
                .animation(.easeInOut(duration: 0.25), value: tick)
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
        .onReceive(timer) { _ in
            guard remaining > 0 else { return }
            remaining -= 1
            tick.toggle()
        }
    }
}
#endif
