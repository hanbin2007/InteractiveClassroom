import Foundation
import MultipeerConnectivity

extension PeerConnectionManager {
    struct CoursePayload: Codable {
        let name: String
        let intro: String
        let scheduledAt: Date
    }

    struct LessonPayload: Codable {
        let title: String
        let intro: String
        let scheduledAt: Date
    }

    // MARK: - Interaction Messaging

    func broadcastStartInteraction(_ request: InteractionRequest) {
        let message = Message(type: "startInteraction", interaction: request)
        sendMessageToServer(message)
    }

    func broadcastStopInteraction() {
        let message = Message(type: "stopInteraction", interaction: nil)
        sendMessageToServer(message)
    }

    func startClass(at startDate: Date) {
        let seconds = max(0, Int(startDate.timeIntervalSinceNow))
        let request = InteractionRequest(
            template: .fullScreen,
            lifecycle: .finite(seconds: seconds),
            content: .countdown
        )
        interactionHandler?.startInteraction(request, broadcast: false)
        let message = Message(type: "startClass", interaction: request)
        sendMessageToServer(message)
        if advertiser != nil {
            classStarted = true
        }
    }

    func endClass() {
        interactionHandler?.endInteraction(broadcast: true)
        advertiser?.stopAdvertisingPeer()
        advertiser = nil
        if !sessions.isEmpty {
            let message = Message(type: "endClass")
            sendMessageToServer(message)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            for sess in self.sessions.values {
                sess.disconnect()
            }
            self.sessions.removeAll()
        }
        connectionStatus = "Not Connected"
        teacherCode = nil
        studentCode = nil
        rolesByPeer.removeAll()
        classStarted = false
    }

    func broadcastCurrentState(to peers: [MCPeerID]? = nil) {
        let coursePayload = currentCourse.map { CoursePayload(name: $0.name, intro: $0.intro, scheduledAt: $0.scheduledAt) }
        let lessonPayload = currentLesson.map { LessonPayload(title: $0.title, intro: $0.intro, scheduledAt: $0.scheduledAt) }
        let message = Message(type: "state", course: coursePayload, lesson: lessonPayload)
        if advertiser != nil {
            if let specific = peers, let data = try? JSONEncoder().encode(message) {
                for peer in specific {
                    if let sess = sessions[peer] {
                        try? sess.send(data, toPeers: [peer], with: .reliable)
                    }
                }
            } else {
                forwardToClients(message)
            }
        } else {
            sendMessageToServer(message)
        }
    }

    func handleInteractionMessage(_ message: Message, from peerID: MCPeerID, session: MCSession) {
        switch message.type {
        case "startClass":
            if let req = message.interaction {
                interactionHandler?.startInteraction(req, broadcast: false)
            }
            classStarted = true
            if advertiser != nil {
                ApplicationWindowManager.closeAllWindowsAndFocus()
                forwardToClients(message, excluding: peerID)
            }
        case "startInteraction":
            if let req = message.interaction {
                interactionHandler?.startInteraction(req, broadcast: false)
                forwardToClients(message, excluding: peerID)
            }
        case "stopInteraction":
            interactionHandler?.endInteraction(broadcast: false)
            let forward = Message(type: "stopInteraction", interaction: nil)
            forwardToClients(forward, excluding: peerID)
        case "endClass":
            interactionHandler?.endInteraction(broadcast: false)
            classStarted = false
            serverDisconnected = true
            userInitiatedDisconnect = true
            session.disconnect()
            myRole = nil
        case "state":
            if let course = message.course {
                currentCourse = Course(name: course.name, intro: course.intro, scheduledAt: course.scheduledAt)
            } else {
                currentCourse = nil
            }
            if let lesson = message.lesson {
                currentLesson = Lesson(title: lesson.title, number: 0, scheduledAt: lesson.scheduledAt, intro: lesson.intro)
            } else {
                currentLesson = nil
            }
        default:
            break
        }
    }
}
