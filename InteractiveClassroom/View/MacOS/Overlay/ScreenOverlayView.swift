#if os(macOS)
import SwiftUI

/// Overlay shown on the big screen during a quiz session.
struct ScreenOverlayView: View {
    @StateObject private var model = ScreenOverlayModel()

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                OverlayTopBarView(questionType: model.questionType.displayName,
                                  remainingTime: model.remainingTimeString)
                OverlayStatsView(stats: model.statsDisplay)
                OverlayNamesView(names: model.submittedNames)
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
        .background(Color.clear)
        .ignoresSafeArea()
        .foregroundStyle(.white)
    }
}
#endif
