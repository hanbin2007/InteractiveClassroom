#if os(macOS)
import SwiftUI

/// Top bar showing question type and remaining time.
struct OverlayTopBarView: View {
    let questionType: String
    let remainingTime: String
    private let padding: CGFloat = 32

    var body: some View {
        VStack {
            HStack {
                Text(questionType)
                    .font(.system(size: 40, weight: .bold))
                    .shadow(color: .black, radius: 2)
                    .padding(.leading, padding)
                    .padding(.top, padding)
                Spacer()
                Text(remainingTime)
                    .font(.system(size: 40, weight: .bold))
                    .shadow(color: .black, radius: 2)
                    .padding(.trailing, padding)
                    .padding(.top, padding)
            }
            Spacer()
        }
    }
}
#endif
