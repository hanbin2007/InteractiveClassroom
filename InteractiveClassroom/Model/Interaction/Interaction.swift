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
struct InteractionRequest: Codable, Equatable {
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
        case multipleChoice(MultipleChoiceQuestion)

        private enum CodingKeys: String, CodingKey { case type, text, question }
        private enum Kind: String, Codable { case text, countdown, multipleChoice }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let kind = try container.decode(Kind.self, forKey: .type)
            switch kind {
            case .text:
                let value = try container.decode(String.self, forKey: .text)
                self = .text(value)
            case .countdown:
                self = .countdown
            case .multipleChoice:
                let question = try container.decode(MultipleChoiceQuestion.self, forKey: .question)
                self = .multipleChoice(question)
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
            case .multipleChoice(let question):
                try container.encode(Kind.multipleChoice, forKey: .type)
                try container.encode(question, forKey: .question)
            }
        }
    }

    var content: Content
    /// Additional stages following the main stage.
    var stages: [InteractionStage]? = nil

    /// Builds an overlay container based on the request.
    /// - Parameter countdownService: Optional service used for countdown interactions
    ///   to maintain timer state even when the overlay view is removed.
    @MainActor
    func makeOverlay(content override: Content? = nil, countdownService: CountdownService? = nil) -> OverlayContent {
        let overlayTemplate: OverlayTemplate
        switch template {
        case .fullScreen:
            overlayTemplate = .fullScreen(color: .black)
        case .floatingCorner:
            overlayTemplate = .floatingCorner(position: .bottomRight)
        }
        let displayContent = override ?? content
        return OverlayContent(template: overlayTemplate) {
            switch displayContent {
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
            case .multipleChoice(let question):
                #if os(macOS)
                if let service = countdownService {
                    MultipleChoiceOverlayView(
                        viewModel: MultipleChoiceOverlayViewModel(question: question),
                        service: service
                    )
                } else {
                    let service = CountdownService(seconds: lifecycle.secondsValue ?? 0)
                    MultipleChoiceOverlayView(
                        viewModel: MultipleChoiceOverlayViewModel(question: question),
                        service: service
                    )
                }
                #else
                EmptyView()
                #endif
            }
        }
    }
}

/// Represents a running interaction with its stages and current progress.
struct Interaction {
    let request: InteractionRequest
    /// Ordered stages for this interaction.
    let stages: [InteractionStage]
    let startedAt: Date = Date()
    fileprivate(set) var currentStageIndex: Int

    init(request: InteractionRequest, stageIndex: Int = 0) {
        self.request = request
        var allStages = [InteractionStage(id: 0, content: request.content)]
        if let extras = request.stages {
            allStages.append(contentsOf: extras)
        }
        self.stages = allStages.sorted { $0.id < $1.id }
        self.currentStageIndex = min(stageIndex, self.stages.count - 1)
    }

    /// The stage currently being presented.
    var currentStage: InteractionStage { stages[currentStageIndex] }
    /// Whether the interaction is displaying its final stage.
    var isLastStage: Bool { currentStageIndex >= stages.count - 1 }

    /// Advances to the next stage if available.
    mutating func advanceStage() {
        guard !isLastStage else { return }
        currentStageIndex += 1
    }
}
