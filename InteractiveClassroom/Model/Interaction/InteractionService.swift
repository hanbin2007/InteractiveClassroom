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
    private var cancellables: Set<AnyCancellable> = []

    init(manager: PeerConnectionManager) {
        self.manager = manager

        manager.$overlayContent
            .receive(on: RunLoop.main)
            .sink { [weak self] in self?.overlayContent = $0 }
            .store(in: &cancellables)
        manager.$isOverlayContentVisible
            .receive(on: RunLoop.main)
            .sink { [weak self] in self?.isOverlayContentVisible = $0 }
            .store(in: &cancellables)
        manager.$activeInteraction
            .receive(on: RunLoop.main)
            .sink { [weak self] in self?.activeInteraction = $0 }
            .store(in: &cancellables)
        manager.$countdownService
            .receive(on: RunLoop.main)
            .sink { [weak self] in self?.countdownService = $0 }
            .store(in: &cancellables)
    }

    // MARK: - Interaction Controls

    func presentOverlay(_ content: OverlayContent) { manager.presentOverlay(content: content) }
    func toggleOverlayVisibility() { manager.toggleOverlayContentVisibility() }
    func startInteraction(_ request: InteractionRequest, broadcast: Bool = true) { manager.startInteraction(request, broadcast: broadcast) }
    func endInteraction(broadcast: Bool = true) { manager.endInteraction(broadcast: broadcast) }
}
