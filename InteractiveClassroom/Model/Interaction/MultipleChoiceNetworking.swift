import Foundation

/// Payload sent from a participant when submitting a multiple-choice answer.
struct MultipleChoiceAnswerPayload: Codable {
    /// The display name of the participant.
    let participant: String
    /// Identifiers of selected options.
    let selectedOptionIDs: [String]
}

/// Aggregated result payload broadcast by the server.
struct MultipleChoiceResultPayload: Codable {
    /// Mapping from option identifiers to selection counts.
    let optionCounts: [String: Int]
    /// Names of participants who have submitted answers.
    let submittedNames: [String]
}
