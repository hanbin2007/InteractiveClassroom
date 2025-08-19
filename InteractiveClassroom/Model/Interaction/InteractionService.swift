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

    private let manager: PeerConnectionManager
    private var interactionTask: Task<Void, Never>?
    private var pendingBroadcastPeers: Set<MCPeerID>?
    private let stateBroadcastSubject = PassthroughSubject<Void, Never>()
    private var cancellables: Set<AnyCancellable> = []

    init(manager: PeerConnectionManager) {
        self.manager = manager
        self.manager.interactionHandler = self

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

    // MARK: - Interaction Controls
    func startInteraction(_ request: InteractionRequest, broadcast: Bool = true, remainingSeconds: Int? = nil) {
        if activeInteraction != nil {
            if broadcast {
                let message = PeerConnectionManager.Message(type: "startInteraction", interaction: request)
                manager.sendMessageToServer(message)
            }
            print("[InteractionService] Attempted to start a new interaction while another is active.")
            return
        }
        let interaction = Interaction(request: request)
        activeInteraction = interaction

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
            let remaining = remainingSeconds ?? currentRemainingSeconds()
            let message = PeerConnectionManager.Message(type: "startInteraction", interaction: request, remainingSeconds: remaining)
            manager.sendMessageToServer(message)
        }
        broadcastCurrentState(to: nil)
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
            let message = PeerConnectionManager.Message(type: "stopInteraction", interaction: nil)
            manager.sendMessageToServer(message)
            print("[InteractionService] Sent stop interaction message to server.")
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
    private func currentRemainingSeconds() -> Int? {
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

// MARK: - InteractionHandling
extension InteractionService: @preconcurrency InteractionHandling {
    /// Broadcasts the current course and lesson state to connected peers or the server.
    /// Multiple rapid calls are coalesced into a single message using Combine's `debounce`.
    func broadcastCurrentState(to peers: [MCPeerID]?) {
        if let peers {
            if pendingBroadcastPeers == nil {
                pendingBroadcastPeers = Set(peers)
            } else {
                pendingBroadcastPeers?.formUnion(peers)
            }
        } else {
            pendingBroadcastPeers = nil
        }

        stateBroadcastSubject.send(())
    }

    private func performStateBroadcast() {
        let coursePayload = manager.currentCourse.map {
            PeerConnectionManager.CoursePayload(name: $0.name, intro: $0.intro, scheduledAt: $0.scheduledAt)
        }
        let lessonPayload = manager.currentLesson.map {
            PeerConnectionManager.LessonPayload(title: $0.title, intro: $0.intro, scheduledAt: $0.scheduledAt)
        }
        let message = PeerConnectionManager.Message(
            type: "state",
            course: coursePayload,
            lesson: lessonPayload,
            interaction: activeInteraction?.request,
            remainingSeconds: currentRemainingSeconds()
        )
        if manager.advertiser != nil {
            if let specific = pendingBroadcastPeers, let data = try? JSONEncoder().encode(message) {
                for peer in specific {
                    if let sess = manager.sessions[peer] {
                        try? sess.send(data, toPeers: [peer], with: .reliable)
                    }
                }
            } else {
                manager.forwardToClients(message)
            }
        } else {
            manager.sendMessageToServer(message)
        }
        pendingBroadcastPeers = nil
    }

    private func notifyInteractionInProgress(to peerID: MCPeerID, session: MCSession, request: InteractionRequest?) {
        let message = PeerConnectionManager.Message(
            type: "interactionInProgress",
            interaction: request,
            remainingSeconds: currentRemainingSeconds()
        )
        if let data = try? JSONEncoder().encode(message) {
            try? session.send(data, toPeers: [peerID], with: .reliable)
        }
        print("[InteractionService] Notified \(peerID.displayName) about active interaction.")
    }

    func handleInteractionMessage(_ message: PeerConnectionManager.Message, from peerID: MCPeerID, session: MCSession) {
        switch message.type {
        case "syncTime":
            if let ts = message.timestamp {
                manager.updateTimeOffset(with: ts)
            }
        case "startClass":
            if let req = message.interaction {
                startInteraction(req, broadcast: false)
            }
            manager.classStarted = true
            if manager.advertiser != nil {
                // Close all windows here will cause menubar icon unclickable issue!
                ApplicationWindowManager.closeAllWindowsAndFocus()
                manager.forwardToClients(message, excluding: peerID)
            }
        case "startInteraction":
            if let req = message.interaction {
                if activeInteraction != nil {
                    notifyInteractionInProgress(to: peerID, session: session, request: activeInteraction?.request)
                } else {
                    startInteraction(req, broadcast: false, remainingSeconds: message.remainingSeconds)
                    manager.forwardToClients(message, excluding: peerID)
                }
            }
        case "forceStartInteraction":
            if let req = message.interaction {
                print("[InteractionService] Force starting new interaction from \(peerID.displayName).")
                endInteraction(broadcast: false, broadcastState: false)
                let stopMessage = PeerConnectionManager.Message(type: "stopInteraction", interaction: nil)
                manager.forwardToClients(stopMessage)
                startInteraction(req, broadcast: false, remainingSeconds: message.remainingSeconds)
                let startMessage = PeerConnectionManager.Message(type: "startInteraction", interaction: req, remainingSeconds: message.remainingSeconds)
                manager.forwardToClients(startMessage)
            }
        case "stopInteraction":
            endInteraction(broadcast: false, broadcastState: false)
            let forward = PeerConnectionManager.Message(type: "stopInteraction", interaction: nil)
            manager.forwardToClients(forward, excluding: peerID)
        case "endClass":
            endInteraction(broadcast: false, broadcastState: false)
            manager.classStarted = false
            manager.serverDisconnected = true
            manager.userInitiatedDisconnect = true
            session.disconnect()
            manager.myRole = nil
        case "requestInteractionStatus":
            if manager.advertiser != nil {
                let response = PeerConnectionManager.Message(
                    type: "interactionStatus",
                    interaction: activeInteraction?.request,
                    remainingSeconds: currentRemainingSeconds()
                )
                if let data = try? JSONEncoder().encode(response) {
                    try? session.send(data, toPeers: [peerID], with: .reliable)
                }
                print("[InteractionService] Sent interaction status to \(peerID.displayName).")
            }
        case "interactionStatus":
            if let req = message.interaction {
                startInteraction(req, broadcast: false, remainingSeconds: message.remainingSeconds)
            } else {
                endInteraction(broadcast: false, broadcastState: false)
            }
        case "interactionInProgress":
            if let req = message.interaction {
                print("[InteractionService] Interaction already in progress.")
                startInteraction(req, broadcast: false, remainingSeconds: message.remainingSeconds)
            }
        case "state":
            if let course = message.course {
                manager.currentCourse = Course(name: course.name, intro: course.intro, scheduledAt: course.scheduledAt)
            } else {
                manager.currentCourse = nil
            }
            if let lesson = message.lesson {
                manager.currentLesson = Lesson(title: lesson.title, number: 0, scheduledAt: lesson.scheduledAt, intro: lesson.intro)
            } else {
                manager.currentLesson = nil
            }
            if let req = message.interaction {
                startInteraction(req, broadcast: false, remainingSeconds: message.remainingSeconds)
            } else if activeInteraction != nil {
                endInteraction(broadcast: false, broadcastState: false)
            }
        default:
            break
        }
    }
}

