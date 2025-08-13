#if os(macOS)
import SwiftUI

/// Top bar showing question type and remaining time.
struct OverlayTopBarView: View {
    let questionType: String
    let remainingTime: String
    @ScaledMetric private var horizontalPadding: CGFloat = 32
    @ScaledMetric private var verticalPadding: CGFloat = 32
    @ScaledMetric private var baseFontSize: CGFloat = 34
    @AppStorage("overlayFontScale") private var overlayFontScale: Double = 1.0

    var body: some View {
        VStack {
            HStack {
                Text(questionType)
                    .font(.system(size: baseFontSize * overlayFontScale, weight: .bold))
                    .shadow(color: .black, radius: 2)
                    .padding(.leading, horizontalPadding)
                    .padding(.top, verticalPadding)
                Spacer()
                Text(remainingTime)
                    .font(.system(size: baseFontSize * overlayFontScale, weight: .bold))
                    .shadow(color: .black, radius: 2)
                    .padding(.trailing, horizontalPadding)
                    .padding(.top, verticalPadding)
            }
            Spacer()
        }
    }
}
#endif
