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
    func startInteraction(_ request: InteractionRequest, broadcast: Bool = true) {
        guard activeInteraction == nil else { return }
        let interaction = Interaction(request: request)
        activeInteraction = interaction

        if let seconds = request.lifecycle.secondsValue {
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
            let message = PeerConnectionManager.Message(type: "startInteraction", interaction: request)
            manager.sendMessageToServer(message)
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
            let message = PeerConnectionManager.Message(type: "stopInteraction", interaction: nil)
            manager.sendMessageToServer(message)
        }
    }

    // MARK: - Class Lifecycle
    func startClass(at startDate: Date) {
        let seconds = max(0, Int(startDate.timeIntervalSinceNow))
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
        let message = PeerConnectionManager.Message(type: "state", course: coursePayload, lesson: lessonPayload)
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

    func handleInteractionMessage(_ message: PeerConnectionManager.Message, from peerID: MCPeerID, session: MCSession) {
        switch message.type {
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
                startInteraction(req, broadcast: false)
                manager.forwardToClients(message, excluding: peerID)
            }
        case "stopInteraction":
            endInteraction(broadcast: false)
            let forward = PeerConnectionManager.Message(type: "stopInteraction", interaction: nil)
            manager.forwardToClients(forward, excluding: peerID)
        case "endClass":
            endInteraction(broadcast: false)
            manager.classStarted = false
            manager.serverDisconnected = true
            manager.userInitiatedDisconnect = true
            session.disconnect()
            manager.myRole = nil
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
        default:
            break
        }
    }
}

