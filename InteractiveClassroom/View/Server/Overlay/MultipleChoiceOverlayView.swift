#if os(macOS)
import SwiftUI

/// Overlay presenting multiple-choice statistics and submissions.
struct MultipleChoiceOverlayView: View {
    @ObservedObject var viewModel: MultipleChoiceOverlayViewModel
    @ObservedObject var service: CountdownService

    private func formattedTime(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let seconds = seconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    var body: some View {
        ZStack {
            OverlayTopBarView(
                questionType: "选择题",
                remainingTime: formattedTime(service.remainingSeconds)
            )
            HStack {
                OverlayStatsView(stats: viewModel.stats)
                Spacer()
                OverlayNamesView(names: viewModel.submittedNames)
            }
        }
        .frame(minWidth: 400, minHeight: 300)
    }
}
#endif
