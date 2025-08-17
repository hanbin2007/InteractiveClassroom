#if os(macOS) || os(iOS)
import SwiftUI
import Combine

/// A simple countdown view displaying remaining seconds in the center.
struct CountdownOverlayView: View {
    @State private var remaining: Int
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    init(seconds: Int) {
        _remaining = State(initialValue: max(seconds, 0))
    }

    var body: some View {
        Text("\(remaining)")
            .font(.system(size: 120, weight: .bold, design: .rounded))
            .foregroundColor(.white)
            .monospacedDigit()
            .onReceive(timer) { _ in
                if remaining > 0 { remaining -= 1 }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .multilineTextAlignment(.center)
    }
}
#endif
