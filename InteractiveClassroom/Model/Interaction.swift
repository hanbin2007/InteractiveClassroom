import Foundation
import SwiftUI

/// Lifecycle specification for an interaction.
enum InteractionLifecycle: Codable, Equatable {
    case infinite
    case finite(seconds: Int)

    private enum CodingKeys: String, CodingKey { case type, seconds }
    private enum Kind: String, Codable { case infinite, finite }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let kind = try container.decode(Kind.self, forKey: .type)
        switch kind {
        case .infinite:
            self = .infinite
        case .finite:
            let secs = try container.decode(Int.self, forKey: .seconds)
            self = .finite(seconds: secs)
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .infinite:
            try container.encode(Kind.infinite, forKey: .type)
        case .finite(let seconds):
            try container.encode(Kind.finite, forKey: .type)
            try container.encode(seconds, forKey: .seconds)
        }
    }
}

/// Request payload used to initiate an interaction from the teacher client.
struct InteractionRequest: Codable {
    /// Simplified template placeholder for future expansion.
    enum Template: String, Codable {
        case fullScreen
        case floatingCorner
    }

    var template: Template
    var lifecycle: InteractionLifecycle
    /// Placeholder text representing the interactive content.
    var text: String

    /// Builds an overlay container based on the request.
    func makeOverlay() -> OverlayContent {
        let overlayTemplate: OverlayTemplate
        switch template {
        case .fullScreen:
            overlayTemplate = .fullScreen(color: .black)
        case .floatingCorner:
            overlayTemplate = .floatingCorner(position: .bottomRight)
        }
        return OverlayContent(template: overlayTemplate) {
            Text(text)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding()
        }
    }
}

/// Represents a running interaction with its start time.
struct Interaction {
    let request: InteractionRequest
    let startedAt: Date = Date()
}
