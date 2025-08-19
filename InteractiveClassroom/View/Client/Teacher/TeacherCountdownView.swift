#if os(iOS)
import SwiftUI

/// Countdown display used on the teacher client during an active interaction.
struct TeacherCountdownView: View {
    @ObservedObject var service: CountdownService
    @ScaledMetric private var baseSpacing: CGFloat = 24

    var body: some View {
        VStack(spacing: baseSpacing) {
            Text("Remaining Time")
                .font(.headline)
            CountdownDigitsView(remainingSeconds: service.remainingSeconds, color: .primary)
        }
    }
}
#endif

