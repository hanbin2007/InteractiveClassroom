#if os(iOS) || os(macOS)
import SwiftUI

/// Displays a time string with a vertical rolling animation on digit changes.
struct CountdownDigitsView: View {
    /// Total remaining seconds to display.
    let remainingSeconds: Int

    private var formattedTime: String {
        let minutes = remainingSeconds / 60
        let seconds = remainingSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    var body: some View {
        let text = Text(formattedTime)
            .font(.system(size: 200, weight: .bold, design: .rounded))
            .foregroundColor(.white)
            .monospacedDigit()

        if #available(iOS 17, macOS 14, *) {
            text
                .contentTransition(.numericText())
                .animation(.easeInOut(duration: 0.3), value: remainingSeconds)
        } else {
            text
        }
    }
}
#endif
