import Foundation
import MultipeerConnectivity
import SwiftData
import Combine
#if canImport(UIKit)
import UIKit
#endif

@MainActor
class PeerConnectionManager: NSObject, ObservableObject {
    let serviceType = "iclassrm"
    let myPeerID: MCPeerID
    var session: MCSession
    var sessions: [MCPeerID: MCSession] = [:]
    var advertiser: MCNearbyServiceAdvertiser?
    var browser: MCNearbyServiceBrowser?

    var modelContext: ModelContext?

    struct Peer: Identifiable, Hashable {
        let peerID: MCPeerID
        var id: String { peerID.displayName }
    }

    @Published var availablePeers: [Peer] = []
    @Published var connectionStatus: String = "Not Connected"
    @Published var teacherCode: String?
    @Published var studentCode: String?
    @Published var myRole: UserRole?
    @Published var students: [String] = []
    @Published var classStarted: Bool = false
    @Published var serverDisconnected: Bool = false
    @Published private(set) var connectedServer: MCPeerID?

    weak var interactionHandler: InteractionHandling?

    @Published var currentCourse: Course? {
        didSet { broadcastCurrentState() }
    }
    @Published var currentLesson: Lesson? {
        didSet { broadcastCurrentState() }
    }

    var rolesByPeer: [MCPeerID: UserRole] = [:]
    var userInitiatedDisconnect = false

    struct InvitationPayload: Codable {
        let passcode: String
        let nickname: String
    }

    struct Message: Codable {
        let type: String
        let role: String?
        let students: [String]?
        let target: String?
        let course: CoursePayload?
        let lesson: LessonPayload?
        let interaction: InteractionRequest?

        init(type: String,
             role: String? = nil,
             students: [String]? = nil,
             target: String? = nil,
             course: CoursePayload? = nil,
             lesson: LessonPayload? = nil,
             interaction: InteractionRequest? = nil) {
            self.type = type
            self.role = role
            self.students = students
            self.target = target
            self.course = course
            self.lesson = lesson
            self.interaction = interaction
        }
    }

    init(modelContext: ModelContext? = nil, currentCourse: Course? = nil, currentLesson: Lesson? = nil) {
        self.modelContext = modelContext
        self.currentCourse = currentCourse
        self.currentLesson = currentLesson
#if os(macOS)
        myPeerID = MCPeerID(displayName: Host.current().localizedName ?? "macOS")
#else
        myPeerID = MCPeerID(displayName: UIDevice.current.name)
#endif
        session = MCSession(peer: myPeerID, securityIdentity: nil, encryptionPreference: .required)
        super.init()
        session.delegate = self
    }

    override convenience init() {
        self.init(modelContext: nil)
    }

    func sendMessageToServer(_ message: Message) {
        guard let server = connectedServer else { return }
        if let data = try? JSONEncoder().encode(message) {
            try? session.send(data, toPeers: [server], with: .reliable)
        }
    }

    func forwardToClients(_ message: Message, excluding origin: MCPeerID? = nil) {
        guard advertiser != nil else { return }
        if let data = try? JSONEncoder().encode(message) {
            for (peerID, sess) in sessions where peerID != origin {
                if !sess.connectedPeers.isEmpty {
                    try? sess.send(data, toPeers: sess.connectedPeers, with: .reliable)
                }
            }
        }
    }

    // MARK: - Pairing Operations

    private func resolvedCurrentCourse(in context: ModelContext) -> Course? {
        guard let course = currentCourse else { return nil }
        return context.model(for: course.persistentModelID) as? Course
    }
    func isConnected(to peer: Peer) -> Bool {
        connectedServer == peer.peerID
    }

    func disconnectPeer(named name: String) {
        // Subclasses can override to handle targeted disconnection
    }

    private func updateStudents() {
        let currentStudents = rolesByPeer.filter { $0.value == .student }.map { $0.key.displayName }
        students = currentStudents
        let message = Message(type: "students", students: currentStudents)
        sendMessageToServer(message)
    }
}

// MARK: - Advertiser Delegate

extension PeerConnectionManager: MCNearbyServiceAdvertiserDelegate {
    nonisolated func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        let payload = context.flatMap { try? JSONDecoder().decode(InvitationPayload.self, from: $0) }
        Task { @MainActor in
            guard let code = payload?.passcode else {
                invitationHandler(false, nil)
                return
            }
            if code == self.teacherCode {
                if self.rolesByPeer.values.contains(.teacher) {
                    invitationHandler(false, nil)
                    return
                }
                self.rolesByPeer[peerID] = .teacher
            } else if code == self.studentCode {
                self.rolesByPeer[peerID] = .student
            } else {
                invitationHandler(false, nil)
                return
            }
            let newSession = MCSession(peer: self.myPeerID, securityIdentity: nil, encryptionPreference: .required)
            newSession.delegate = self
            self.sessions[peerID] = newSession
            invitationHandler(true, newSession)
            if let context = self.modelContext {
                let name = peerID.displayName
                let predicate = #Predicate<ClientInfo> { $0.deviceName == name }
                let descriptor = FetchDescriptor<ClientInfo>(predicate: predicate)
                let results = (try? context.fetch(descriptor)) ?? []
                let existing = results.first { $0.course?.persistentModelID == self.currentCourse?.persistentModelID }
                let courseRef = self.resolvedCurrentCourse(in: context)
                if let existing {
                    existing.nickname = payload?.nickname ?? existing.nickname
                    existing.role = self.rolesByPeer[peerID]?.rawValue ?? existing.role
                    existing.lastConnected = .now
                    existing.isConnected = true
                    existing.course = courseRef
                } else {
                    let info = ClientInfo(deviceName: name,
                                          nickname: payload?.nickname ?? "",
                                          role: self.rolesByPeer[peerID]?.rawValue ?? "",
                                          ipAddress: nil,
                                          lastConnected: .now,
                                          isConnected: true,
                                          course: courseRef)
                    context.insert(info)
                }
                try? context.save()
            }
        }
    }
}

// MARK: - Browser Delegate

extension PeerConnectionManager: MCNearbyServiceBrowserDelegate {
    nonisolated func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        Task { @MainActor in
            if !self.availablePeers.contains(where: { $0.peerID == peerID }) {
                self.availablePeers.append(Peer(peerID: peerID))
            }
        }
    }

    nonisolated func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        Task { @MainActor in
            self.availablePeers.removeAll { $0.peerID == peerID }
        }
    }
}

// MARK: - Session Delegate

extension PeerConnectionManager: MCSessionDelegate {
    nonisolated func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        Task { @MainActor in
            switch state {
            case .connected:
                if self.advertiser == nil {
                    self.connectionStatus = "Connected to \(peerID.displayName)"
                    self.connectedServer = peerID
                }
                if let role = self.rolesByPeer[peerID] {
                    let message = Message(type: "role", role: role.rawValue)
                    if let data = try? JSONEncoder().encode(message) {
                        try? session.send(data, toPeers: session.connectedPeers, with: .reliable)
                    }
                }
                self.broadcastCurrentState(to: [peerID])
                self.updateStudents()
                if let context = self.modelContext {
                    let name = peerID.displayName
                    let predicate = #Predicate<ClientInfo> { $0.deviceName == name }
                    let descriptor = FetchDescriptor<ClientInfo>(predicate: predicate)
                    let results = (try? context.fetch(descriptor)) ?? []
                    if let existing = results.first(where: { $0.course?.persistentModelID == self.currentCourse?.persistentModelID }) {
                        existing.isConnected = true
                        existing.lastConnected = .now
                        try? context.save()
                    }
                }
            case .connecting:
                if self.advertiser == nil {
                    self.connectionStatus = "Connecting to \(peerID.displayName)..."
                }
            case .notConnected:
                let actingAsClient = self.advertiser == nil
                self.rolesByPeer.removeValue(forKey: peerID)
                self.updateStudents()
                if actingAsClient {
                    if self.connectedServer == peerID {
                        self.connectionStatus = "Not Connected"
                        self.connectedServer = nil
                        if self.userInitiatedDisconnect {
                            self.userInitiatedDisconnect = false
                        } else if self.myRole != nil {
                            self.serverDisconnected = true
                        }
                        self.myRole = nil
                    }
                } else {
                    self.userInitiatedDisconnect = false
                    self.sessions.removeValue(forKey: peerID)
                }
                if let context = self.modelContext {
                    let name = peerID.displayName
                    let predicate = #Predicate<ClientInfo> { $0.deviceName == name }
                    let descriptor = FetchDescriptor<ClientInfo>(predicate: predicate)
                    let results = (try? context.fetch(descriptor)) ?? []
                    if let existing = results.first(where: { $0.course?.persistentModelID == self.currentCourse?.persistentModelID }) {
                        existing.isConnected = false
                        try? context.save()
                    }
                }
            @unknown default:
                self.connectionStatus = "Unknown State"
            }
        }
    }

    nonisolated func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        Task { @MainActor in
            guard let message = try? JSONDecoder().decode(Message.self, from: data) else { return }
            switch message.type {
            case "role":
                if let r = message.role, let role = UserRole(rawValue: r) {
                    self.myRole = role
                }
            case "students":
                self.students = message.students ?? []
            case "disconnect":
                if let target = message.target {
                    self.disconnectPeer(named: target)
                }
            case "requestStudents":
                if self.advertiser != nil {
                    self.updateStudents()
                }
            default:
                self.handleInteractionMessage(message, from: peerID, session: session)
            }
        }
    }

    nonisolated func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {}
    nonisolated func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {}
    nonisolated func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {}
    nonisolated func session(_ session: MCSession, didReceiveCertificate certificate: [Any]?, fromPeer peerID: MCPeerID, certificateHandler: @escaping (Bool) -> Void) {
        certificateHandler(true)
    }
}
