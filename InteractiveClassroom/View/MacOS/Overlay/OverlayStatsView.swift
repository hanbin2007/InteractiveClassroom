#if os(macOS)
import SwiftUI

/// Left side statistics for quiz results.
struct OverlayStatsView: View {
    let stats: [String]
    @ScaledMetric private var leadingPadding: CGFloat = 32
    @ScaledMetric private var baseFontSize: CGFloat = 20
    @AppStorage("overlayContentScale") private var overlayContentScale: Double = 1.0

    var body: some View {
        HStack {
            if !stats.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(stats, id: \.self) { stat in
                        Text(stat)
                            .font(.system(size: baseFontSize * overlayContentScale))
                            .shadow(color: .black, radius: 1)
                    }
                }
                .padding(.leading, leadingPadding)
            }
            Spacer()
        }
    }
}
#Preview {
    OverlayStatsView(stats: ["A: 50%", "B: 30%", "C: 20%"])
}
#endif
