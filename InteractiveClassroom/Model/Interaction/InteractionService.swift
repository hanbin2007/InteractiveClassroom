import Foundation
import SwiftUI
import MultipeerConnectivity
import Combine

@MainActor
final class InteractionService: ObservableObject {
    @Published private(set) var overlayContent: OverlayContent?
    @Published private(set) var isOverlayContentVisible: Bool = false
    @Published private(set) var activeInteraction: Interaction?
    @Published var countdownService: CountdownService?

    let manager: PeerConnectionManager
    private var interactionTask: Task<Void, Never>?
    var pendingBroadcastPeers: Set<MCPeerID>?
    let stateBroadcastSubject = PassthroughSubject<Void, Never>()
    private var cancellables: Set<AnyCancellable> = []
    private var lastInteractionChange: Date?
    private var debounceInterval: TimeInterval {
        let enabled = UserDefaults.standard.bool(forKey: "interactionDebounceEnabled")
        guard enabled else { return 0 }
        return UserDefaults.standard.double(forKey: "interactionDebounceInterval")
    }

    init(manager: PeerConnectionManager) {
        self.manager = manager
        self.manager.interactionHandler = self

        UserDefaults.standard.register(defaults: [
            "interactionDebounceEnabled": true,
            "interactionDebounceInterval": 2.0
        ])

        stateBroadcastSubject
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .sink { [weak self] in
                self?.performStateBroadcast()
            }
            .store(in: &cancellables)
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

    private func canChangeInteraction() -> Bool {
        let interval = debounceInterval
        guard interval > 0, let last = lastInteractionChange else { return true }
        return Date().timeIntervalSince(last) >= interval
    }

    // MARK: - Interaction Controls
    func startInteraction(_ request: InteractionRequest, broadcast: Bool = true, remainingSeconds: Int? = nil) {
        guard canChangeInteraction() else {
            print("[InteractionService] Start ignored due to debounce interval.")
            return
        }
        if activeInteraction != nil {
            if broadcast {
                broadcastStartInteraction(request, remainingSeconds: remainingSeconds)
            }
            print("[InteractionService] Attempted to start a new interaction while another is active.")
            return
        }
        let interaction = Interaction(request: request)
        activeInteraction = interaction
        lastInteractionChange = Date()

        if let seconds = remainingSeconds ?? request.lifecycle.secondsValue {
            let service = CountdownService(seconds: seconds)
            countdownService = service
            presentOverlay(request.makeOverlay(countdownService: service))
            service.start { [weak self] in
                self?.endInteraction()
            }
        } else {
            presentOverlay(request.makeOverlay())
        }

        if broadcast {
            broadcastStartInteraction(request, remainingSeconds: remainingSeconds)
            broadcastCurrentState(to: nil)
        } else if manager.advertiser != nil {
            // When acting as the server, share the updated state with connected clients.
            // Clients receiving this state will not rebroadcast, preventing start/end loops.
            broadcastCurrentState(to: nil)
        }
    }

    /// Protocol requirement convenience wrapper.
    func startInteraction(_ request: InteractionRequest, broadcast: Bool) {
        startInteraction(request, broadcast: broadcast, remainingSeconds: nil)
    }

    /// Forcefully requests the server to terminate any active interaction and start the provided one.
    func forceStartInteraction(_ request: InteractionRequest) {
        let message = PeerConnectionManager.Message(type: "forceStartInteraction", interaction: request)
        manager.sendMessageToServer(message)
        print("[InteractionService] Sent force start interaction request to server.")
    }

    func endInteraction(broadcast: Bool = true, broadcastState: Bool = false) {
        guard activeInteraction != nil else { return }
        guard canChangeInteraction() else {
            print("[InteractionService] End ignored due to debounce interval.")
            return
        }
        lastInteractionChange = Date()
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
            broadcastStopInteraction()
        }
        if broadcastState {
            broadcastCurrentState(to: nil)
            print("[InteractionService] Broadcasted interaction state after ending.")
        }
    }

    /// Requests the current interaction status from the server.
    func requestInteractionStatus() {
        let message = PeerConnectionManager.Message(type: "requestInteractionStatus")
        manager.sendMessageToServer(message)
        print("[InteractionService] Requested interaction status from server.")
    }

    /// Calculates remaining seconds for the current interaction if finite.
    func currentRemainingSeconds() -> Int? {
        guard let interaction = activeInteraction,
              case let .finite(seconds) = interaction.request.lifecycle else { return nil }
        let elapsed = Int(Date().timeIntervalSince(interaction.startedAt))
        return max(0, seconds - elapsed)
    }

    // MARK: - Class Lifecycle
    func startClass(at startDate: Date) {
        let serverDate = startDate.addingTimeInterval(manager.timeOffset)
        let seconds = max(0, Int(serverDate.timeIntervalSinceNow))
        let request = InteractionRequest(
            template: .fullScreen,
            lifecycle: .finite(seconds: seconds),
            content: .countdown
        )
        startInteraction(request, broadcast: false)
        let message = PeerConnectionManager.Message(type: "startClass", interaction: request)
        manager.sendMessageToServer(message)
        if manager.advertiser != nil {
            manager.classStarted = true
        }
    }

    func endClass() {
        endInteraction(broadcast: true)
        manager.advertiser?.stopAdvertisingPeer()
        manager.advertiser = nil
        if !manager.sessions.isEmpty {
            let message = PeerConnectionManager.Message(type: "endClass")
            manager.sendMessageToServer(message)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak manager] in
            guard let manager else { return }
            for sess in manager.sessions.values {
                sess.disconnect()
            }
            manager.sessions.removeAll()
        }
        manager.connectionStatus = "Not Connected"
        manager.teacherCode = nil
        manager.studentCode = nil
        manager.rolesByPeer.removeAll()
        manager.classStarted = false
    }
}

