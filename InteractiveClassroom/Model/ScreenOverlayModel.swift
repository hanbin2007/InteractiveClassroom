#if os(macOS)
import Foundation

/// Observable model backing the macOS big-screen overlay.
@MainActor
final class ScreenOverlayModel: ObservableObject {
    /// Remaining time in seconds for the current question.
    @Published var remainingTime: Int = 300
    /// Current question type.
    @Published var questionType: QuestionType = .singleChoice
    /// Names of students who have submitted their answers.
    @Published var submittedNames: [String] = ["Alice", "Bob", "Charlie"]
    /// Answer ratios for choice questions (e.g. "A":0.5 means 50%).
    @Published var choiceRatios: [String: Double]? = ["A": 0.5, "B": 0.3, "C": 0.2]
    /// High-frequency answers for fill-in-the-blank questions.
    @Published var fillBlankAnswers: [String: Int]? = nil

    enum QuestionType: String {
        case singleChoice = "单选"
        case multipleChoice = "多选"
        case fillInBlank = "填空"

        var displayName: String { rawValue }
    }

    /// Formats remaining time as mm:ss.
    var remainingTimeString: String {
        let minutes = remainingTime / 60
        let seconds = remainingTime % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    /// Textual representation of statistics on the left side.
    var statsDisplay: [String] {
        if let ratios = choiceRatios {
            return ratios
                .sorted { $0.key < $1.key }
                .map { "\($0.key): \(Int($0.value * 100))%" }
        }
        if let answers = fillBlankAnswers {
            return answers
                .sorted { $0.value > $1.value }
                .map { "\($0.key): \($0.value)" }
        }
        return []
    }
}
#endif
