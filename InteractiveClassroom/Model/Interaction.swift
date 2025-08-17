import Foundation

/// Represents a type of interactive activity shown on the overlay.
enum Interaction: String, Codable {
    /// Displays a list of online students at the end of class.
    case classSummary
    // Future interactions such as quizzes can be added here.
}
