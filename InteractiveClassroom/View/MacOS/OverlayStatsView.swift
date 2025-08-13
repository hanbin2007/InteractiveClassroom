#if os(macOS)
import SwiftUI

/// Left side statistics for quiz results.
struct OverlayStatsView: View {
    let stats: [String]
    private let padding: CGFloat = 32

    var body: some View {
        HStack {
            if !stats.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(stats, id: \.self) { stat in
                        Text(stat)
                            .font(.title3)
                            .shadow(color: .black, radius: 1)
                    }
                }
                .padding(.leading, padding)
            }
            Spacer()
        }
    }
}
#endif
