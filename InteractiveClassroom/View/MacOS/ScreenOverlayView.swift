#if os(macOS)
import SwiftUI

/// Overlay shown on the big screen during a quiz session.
struct ScreenOverlayView: View {
    @StateObject private var model = ScreenOverlayModel()

    var body: some View {
        ZStack {
            Color.black.opacity(0.8)
                .ignoresSafeArea()
            GeometryReader { _ in
                let padding: CGFloat = 32
                // Top area with question type and remaining time
                VStack {
                    HStack {
                        Text(model.questionType.displayName)
                            .font(.system(size: 40, weight: .bold))
                            .padding(.leading, padding)
                            .padding(.top, padding)
                        Spacer()
                        Text(model.remainingTimeString)
                            .font(.system(size: 40, weight: .bold))
                            .padding(.trailing, padding)
                            .padding(.top, padding)
                    }
                    Spacer()
                }
                // Left side statistics
                HStack {
                    if !model.statsDisplay.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(model.statsDisplay, id: .self) { stat in
                                Text(stat)
                                    .font(.title3)
                            }
                        }
                        .padding(.leading, padding)
                    }
                    Spacer()
                }
                // Right side submitted names
                HStack {
                    Spacer()
                    VStack(alignment: .trailing, spacing: 8) {
                        ForEach(model.submittedNames, id: .self) { name in
                            Text(name)
                                .font(.title3)
                        }
                    }
                    .padding(.trailing, padding)
                }
            }
        }
        .foregroundStyle(.white)
    }
}
#endif
