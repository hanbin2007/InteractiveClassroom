import Foundation
import MultipeerConnectivity
import Combine

protocol InteractionHandling: AnyObject {
    func startInteraction(_ request: InteractionRequest, broadcast: Bool)
    func endInteraction(broadcast: Bool, broadcastState: Bool)
    func broadcastCurrentState(to peers: [MCPeerID]?)
    func handleInteractionMessage(_ message: PeerConnectionManager.Message, from peerID: MCPeerID, session: MCSession)
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

    func performStateBroadcast() {
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
                guard activeInteraction?.request != req else { return }
                startInteraction(req, broadcast: false)
            }
            manager.classStarted = true
            if manager.advertiser != nil {
                // Close all windows here will cause menubar icon unclickable issue!
//                ApplicationWindowManager.closeAllWindowsAndFocus()
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
                guard activeInteraction?.request != req else { return }
                startInteraction(req, broadcast: false, remainingSeconds: message.remainingSeconds)
            } else {
                endInteraction(broadcast: false, broadcastState: false)
            }
        case "interactionInProgress":
            if let req = message.interaction {
                guard activeInteraction?.request != req else { return }
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
                guard activeInteraction?.request != req else { return }
                startInteraction(req, broadcast: false, remainingSeconds: message.remainingSeconds)
            } else if activeInteraction != nil {
                endInteraction(broadcast: false, broadcastState: false)
            }
        default:
            break
        }
    }
}
