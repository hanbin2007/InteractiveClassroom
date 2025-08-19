import Foundation

/// Represents a single stage within an interaction.
struct InteractionStage: Codable, Equatable, Identifiable {
    /// Sequential identifier for ordering stages.
    let id: Int
    /// Content to present during this stage.
    let content: InteractionRequest.Content
}
