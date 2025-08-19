#if os(iOS)
import SwiftUI

/// Displays the current interaction state and provides controls to stop it.
struct InteractionStatusView: View {
    @EnvironmentObject private var interactionService: InteractionService
    @StateObject private var viewModel = InteractionStatusViewModel()
    @ScaledMetric private var baseSpacing: CGFloat = 24

    var body: some View {
        VStack(spacing: baseSpacing) {
            if let service = viewModel.countdownService,
               viewModel.activeInteraction != nil {
                TeacherCountdownView(service: service)
            }
            if viewModel.activeInteraction != nil {
                HStack(spacing: baseSpacing) {
                    if viewModel.canAdvanceStage {
                        Button("Next Stage") {
                            viewModel.advanceStage()
                        }
                        .buttonStyle(.bordered)
                    }
                    Button("Stop Interaction") {
                        viewModel.stopCurrentInteraction()
                    }
                    .buttonStyle(.borderedProminent)
                }
            } else {
                Text("No active interaction")
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Status")
        .onAppear { viewModel.bind(to: interactionService) }
    }
}
#endif
