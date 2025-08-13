#if os(macOS)
import SwiftUI

/// Right side list of students who submitted answers.
struct OverlayNamesView: View {
    let names: [String]
    @ScaledMetric private var trailingPadding: CGFloat = 32

    var body: some View {
        HStack {
            Spacer()
            VStack(alignment: .trailing, spacing: 8) {
                ForEach(names, id: \.self) { name in
                    Text(name)
                        .font(.title3)
                        .shadow(color: .black, radius: 1)
                }
            }
            .padding(.trailing, trailingPadding)
        }
    }
}
#endif
