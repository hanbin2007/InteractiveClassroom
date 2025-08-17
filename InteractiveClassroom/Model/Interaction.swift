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

    /// Returns the associated seconds if the lifecycle is finite.
    var secondsValue: Int? {
        if case let .finite(seconds) = self { return seconds } else { return nil }
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

    /// Content type for the interaction.
    enum Content: Codable, Equatable {
        case text(String)
        case countdown

        private enum CodingKeys: String, CodingKey { case type, text }
        private enum Kind: String, Codable { case text, countdown }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let kind = try container.decode(Kind.self, forKey: .type)
            switch kind {
            case .text:
                let value = try container.decode(String.self, forKey: .text)
                self = .text(value)
            case .countdown:
                self = .countdown
            }
        }

        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            switch self {
            case .text(let value):
                try container.encode(Kind.text, forKey: .type)
                try container.encode(value, forKey: .text)
            case .countdown:
                try container.encode(Kind.countdown, forKey: .type)
            }
        }
    }

    var content: Content

    /// Builds an overlay container based on the request.
    /// - Parameter countdownService: Optional service used for countdown interactions
    ///   to maintain timer state even when the overlay view is removed.
    func makeOverlay(countdownService: CountdownService? = nil) -> OverlayContent {
        let overlayTemplate: OverlayTemplate
        switch template {
        case .fullScreen:
            overlayTemplate = .fullScreen(color: .black)
        case .floatingCorner:
            overlayTemplate = .floatingCorner(position: .bottomRight)
        }
        return OverlayContent(template: overlayTemplate) {
            switch content {
            case .text(let text):
                Text(text)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding()
            case .countdown:
                if let service = countdownService {
                    CountdownOverlayView(service: service)
                } else {
                    CountdownOverlayView(service: CountdownService(seconds: lifecycle.secondsValue ?? 0))
                }
            }
        }
    }
}

/// Represents a running interaction with its start time.
struct Interaction {
    let request: InteractionRequest
    let startedAt: Date = Date()
}
