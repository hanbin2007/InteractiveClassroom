import Foundation
import Combine
import SwiftUI

@MainActor
final class InteractionService: ObservableObject {
    @Published private(set) var overlayContent: OverlayContent?
    @Published private(set) var isOverlayContentVisible: Bool = false
    @Published private(set) var activeInteraction: Interaction?
    @Published var countdownService: CountdownService?

    private let manager: PeerConnectionManager
    private var interactionTask: Task<Void, Never>?

    init(manager: PeerConnectionManager) {
        self.manager = manager
        self.manager.interactionHandler = self
    }

    var overlayHasContent: Bool { overlayContent != nil }

    // MARK: - Overlay Management
    private func presentOverlay(_ content: OverlayContent) {
        overlayContent = content
        withAnimation(.easeInOut(duration: 0.3)) {
            isOverlayContentVisible = true
        }
    }

    func toggleOverlayVisibility() {
        guard overlayContent != nil else { return }
        withAnimation(.easeInOut(duration: 0.3)) {
            isOverlayContentVisible.toggle()
        }
    }

    // MARK: - Interaction Controls
    func startInteraction(_ request: InteractionRequest, broadcast: Bool = true) {
        guard activeInteraction == nil else { return }
        let interaction = Interaction(request: request)
        activeInteraction = interaction

        if case .countdown = request.content,
           let seconds = request.lifecycle.secondsValue {
            let service = CountdownService(seconds: seconds)
            countdownService = service
            presentOverlay(request.makeOverlay(countdownService: service))
            service.start { [weak self] in
                self?.endInteraction()
            }
        } else {
            presentOverlay(request.makeOverlay())
            if case let .finite(seconds) = request.lifecycle {
                interactionTask = Task { @MainActor [weak self] in
                    try? await Task.sleep(nanoseconds: UInt64(seconds) * 1_000_000_000)
                    self?.endInteraction()
                }
            }
        }

        if broadcast {
            manager.broadcastStartInteraction(request)
        }
    }

    func endInteraction(broadcast: Bool = true) {
        guard activeInteraction != nil else { return }
        withAnimation(.easeInOut(duration: 0.3)) {
            isOverlayContentVisible = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.overlayContent = nil
        }
        activeInteraction = nil
        interactionTask?.cancel()
        interactionTask = nil
        countdownService?.stop()
        countdownService = nil
        if broadcast {
            manager.broadcastStopInteraction()
        }
    }
}

extension InteractionService: @preconcurrency InteractionHandling {}
