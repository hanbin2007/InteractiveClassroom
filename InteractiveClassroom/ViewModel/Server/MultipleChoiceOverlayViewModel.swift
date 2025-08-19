#if os(macOS)
import Foundation
import Combine

/// View model powering the multiple-choice overlay.
@MainActor
final class MultipleChoiceOverlayViewModel: ObservableObject {
    let question: MultipleChoiceQuestion
    /// Human-readable statistics for each option (e.g., "A: 50%").
    @Published var stats: [String]
    /// Names of participants who have submitted answers.
    @Published var submittedNames: [String] = []

    init(question: MultipleChoiceQuestion) {
        self.question = question
        self.stats = question.options.map { "\($0.text): 0%" }
    }
}
#endif
