import Foundation

/// Represents a multiple-choice question configuration.
struct MultipleChoiceQuestion: Codable, Equatable {
    /// An individual selectable option.
    struct Option: Codable, Identifiable, Equatable {
        /// Unique identifier for the option.
        var id: String
        /// Display text for the option.
        var text: String
    }

    /// All available options for the question.
    var options: [Option]
    /// Identifiers of the correct options.
    var correctOptionIDs: [String]
    /// Indicates whether multiple selections are allowed.
    var allowsMultipleSelection: Bool
}
