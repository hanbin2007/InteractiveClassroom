#if os(macOS)
import SwiftUI

/// Right side list of students who submitted answers.
struct OverlayNamesView: View {
    let names: [String]
    @ScaledMetric private var trailingPadding: CGFloat = 32
    @ScaledMetric private var baseFontSize: CGFloat = 20
    @AppStorage("overlayFontScale") private var overlayFontScale: Double = 1.0

    var body: some View {
        HStack {
            Spacer()
            VStack(alignment: .trailing, spacing: 8) {
                ForEach(names, id: \.self) { name in
                    Text(name)
                        .font(.system(size: baseFontSize * overlayFontScale))
                        .shadow(color: .black, radius: 1)
                }
            }
            .padding(.trailing, trailingPadding)
        }
    }
}
#Preview {
    OverlayNamesView(names: ["Alice", "Bob", "Charlie"])
}
#endif
