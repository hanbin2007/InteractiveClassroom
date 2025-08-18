import Foundation
import MultipeerConnectivity
import SwiftData
import Combine
#if canImport(UIKit)
import UIKit
#endif

@MainActor
final class PeerConnectionManager: NSObject, ObservableObject {
    private let serviceType = "iclassrm"
    private let myPeerID: MCPeerID
    private var session: MCSession
    private var sessions: [MCPeerID: MCSession] = [:]
    private var advertiser: MCNearbyServiceAdvertiser?
    private var browser: MCNearbyServiceBrowser?

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

    private struct InvitationPayload: Codable {
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

    func openClassroom() {
        teacherCode = String(format: "%06d", Int.random(in: 0..<1_000_000))
        studentCode = String(format: "%06d", Int.random(in: 0..<1_000_000))
        advertiser = MCNearbyServiceAdvertiser(peer: myPeerID, discoveryInfo: nil, serviceType: serviceType)
        advertiser?.delegate = self
        advertiser?.startAdvertisingPeer()
        connectionStatus = "Awaiting connection..."
        sessions.removeAll()
        refreshConnectedClients()
    }

    func startBrowsing() {
        browser = MCNearbyServiceBrowser(peer: myPeerID, serviceType: serviceType)
        browser?.delegate = self
        browser?.startBrowsingForPeers()
    }

    func stopBrowsing() {
        browser?.stopBrowsingForPeers()
        browser = nil
        availablePeers.removeAll()
    }

    func connect(to peer: Peer, passcode: String, nickname: String) {
        connectionStatus = "Connecting to \(peer.peerID.displayName)..."
        let payload = InvitationPayload(passcode: passcode, nickname: nickname)
        let context = try? JSONEncoder().encode(payload)
        browser?.invitePeer(peer.peerID, to: session, withContext: context, timeout: 30)
    }

    private func resolvedCurrentCourse(in context: ModelContext) -> Course? {
        guard let course = currentCourse else { return nil }
        return context.model(for: course.persistentModelID) as? Course
    }

    func isConnected(to peer: Peer) -> Bool {
        connectedServer == peer.peerID
    }

    func disconnectFromServer() {
        guard advertiser == nil else { return }
        userInitiatedDisconnect = true
        session.disconnect()
        connectionStatus = "Not Connected"
        myRole = nil
        students.removeAll()
        classStarted = false
        currentCourse = nil
        currentLesson = nil
        connectedServer = nil
    }

    func disconnect(peerNamed name: String) {
        guard advertiser != nil else { return }
        if let (peerID, sess) = sessions.first(where: { $0.key.displayName == name }) {
            sess.disconnect()
            sessions.removeValue(forKey: peerID)
        }
    }

    func sendDisconnectCommand(for name: String) {
        guard advertiser == nil, let server = connectedServer else { return }
        let message = Message(type: "disconnect", target: name)
        if let data = try? JSONEncoder().encode(message) {
            try? session.send(data, toPeers: [server], with: .reliable)
        }
    }

    func requestStudentList() {
        guard advertiser == nil, let server = connectedServer else { return }
        let message = Message(type: "requestStudents")
        if let data = try? JSONEncoder().encode(message) {
            try? session.send(data, toPeers: [server], with: .reliable)
        }
    }

    private func updateStudents() {
        let currentStudents = rolesByPeer.filter { $0.value == .student }.map { $0.key.displayName }
        students = currentStudents
        let message = Message(type: "students", students: currentStudents)
        sendMessageToServer(message)
    }

    func refreshConnectedClients() {
        guard let context = modelContext else { return }
        let descriptor = FetchDescriptor<ClientInfo>(predicate: #Predicate { $0.isConnected })
        if let clients = try? context.fetch(descriptor) {
            let activeNames = advertiser != nil ?
                Set(sessions.keys.map { $0.displayName }) :
                Set(session.connectedPeers.map { $0.displayName })
            for client in clients where !activeNames.contains(client.deviceName) {
                client.isConnected = false
            }
            try? context.save()
        }
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
                if let target = message.target, self.advertiser != nil {
                    self.disconnect(peerNamed: target)
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
