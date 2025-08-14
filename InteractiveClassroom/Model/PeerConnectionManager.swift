import Foundation
import MultipeerConnectivity
import SwiftData
#if canImport(UIKit)
import UIKit
#endif

@MainActor
final class PeerConnectionManager: NSObject, ObservableObject {
    private let serviceType = "iclassrm"
    private let myPeerID: MCPeerID
    private var session: MCSession
    private var advertiser: MCNearbyServiceAdvertiser?
    private var browser: MCNearbyServiceBrowser?

    /// Storage context for persisting client information.
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
    /// Indicates that the client lost connection to the server.
    @Published var serverDisconnected: Bool = false
    /// Currently connected server when acting as a client.
    @Published private(set) var connectedServer: MCPeerID?
    /// Currently selected course.
    @Published var currentCourse: Course? {
        didSet { broadcastCurrentState() }
    }
    /// Currently selected lesson.
    @Published var currentLesson: Lesson? {
        didSet { broadcastCurrentState() }
    }

    /// Mapping of connected peers to their assigned roles.
    private var rolesByPeer: [MCPeerID: UserRole] = [:]

    /// Tracks whether the client initiated a disconnect to avoid user-facing alerts.
    private var userInitiatedDisconnect = false

    /// Payload sent during connection containing passcode and nickname.
    private struct InvitationPayload: Codable {
        let passcode: String
        let nickname: String
    }

    /// Generic message exchanged after connection to coordinate state.
    private struct Message: Codable {
        let type: String
        let role: String?
        let students: [String]?
        let target: String?
        let course: CoursePayload?
        let lesson: LessonPayload?

        init(type: String,
             role: String? = nil,
             students: [String]? = nil,
             target: String? = nil,
             course: CoursePayload? = nil,
             lesson: LessonPayload? = nil) {
            self.type = type
            self.role = role
            self.students = students
            self.target = target
            self.course = course
            self.lesson = lesson
        }
    }

    /// Light-weight representation of a course for network transfer.
    private struct CoursePayload: Codable {
        let name: String
        let intro: String
        let scheduledAt: Date
    }

    /// Light-weight representation of a lesson for network transfer.
    private struct LessonPayload: Codable {
        let title: String
        let intro: String
        let scheduledAt: Date
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

    func startHosting() {
        teacherCode = String(format: "%06d", Int.random(in: 0..<1_000_000))
        studentCode = String(format: "%06d", Int.random(in: 0..<1_000_000))
        advertiser = MCNearbyServiceAdvertiser(peer: myPeerID, discoveryInfo: nil, serviceType: serviceType)
        advertiser?.delegate = self
        advertiser?.startAdvertisingPeer()
        connectionStatus = "Awaiting connection..."
        refreshConnectedClients()
    }

    func stopHosting() {
        advertiser?.stopAdvertisingPeer()
        advertiser = nil
        if !session.connectedPeers.isEmpty {
            let message = Message(type: "endClass", role: nil, students: nil, target: nil, course: nil, lesson: nil)
            if let data = try? JSONEncoder().encode(message) {
                try? session.send(data, toPeers: session.connectedPeers, with: .reliable)
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.session.disconnect()
        }
        connectionStatus = "Not Connected"
        teacherCode = nil
        studentCode = nil
        rolesByPeer.removeAll()
        classStarted = false
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
        // Update status immediately so UI can react even if the invitation is rejected
        // before a session state change is reported. This ensures client-side alerts
        // are triggered for invalid passcodes or other errors.
        connectionStatus = "Connecting to \(peer.peerID.displayName)..."
        let payload = InvitationPayload(passcode: passcode, nickname: nickname)
        let context = try? JSONEncoder().encode(payload)
        browser?.invitePeer(peer.peerID, to: session, withContext: context, timeout: 30)
    }

    /// Indicates whether the client is already connected to the specified peer.
    func isConnected(to peer: Peer) -> Bool {
        connectedServer == peer.peerID
    }

    /// Sends current course and lesson details to connected peers.
    private func broadcastCurrentState(to peers: [MCPeerID]? = nil) {
        guard advertiser != nil else { return }
        let coursePayload = currentCourse.map { CoursePayload(name: $0.name, intro: $0.intro, scheduledAt: $0.scheduledAt) }
        let lessonPayload = currentLesson.map { LessonPayload(title: $0.title, intro: $0.intro, scheduledAt: $0.scheduledAt) }
        let message = Message(type: "state", course: coursePayload, lesson: lessonPayload)
        if let data = try? JSONEncoder().encode(message) {
            let targets = peers ?? session.connectedPeers
            if !targets.isEmpty {
                try? session.send(data, toPeers: targets, with: .reliable)
            }
        }
    }

    /// Gracefully disconnects from the current server and resets state.
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

    /// Disconnects from a specific peer based on its display name.
    func disconnect(peerNamed name: String) {
        if let peer = session.connectedPeers.first(where: { $0.displayName == name }) {
            session.cancelConnectPeer(peer)
        }
    }

    /// Sends a command to the server to disconnect a specific student.
    func sendDisconnectCommand(for name: String) {
        let message = Message(type: "disconnect", role: nil, students: nil, target: name)
        if let data = try? JSONEncoder().encode(message) {
            try? session.send(data, toPeers: session.connectedPeers, with: .reliable)
        }
    }

    /// Broadcasts a start-class command to the server.
    func startClass() {
        let message = Message(type: "startClass", role: nil, students: nil, target: nil)
        if let data = try? JSONEncoder().encode(message) {
            try? session.send(data, toPeers: session.connectedPeers, with: .reliable)
        }
        // macOS overlay window presentation is now handled by SwiftUI state.
    }

    /// Updates the internal student list and notifies the teacher if connected.
    private func updateStudents() {
        let currentStudents = rolesByPeer.filter { $0.value == .student }.map { $0.key.displayName }
        students = currentStudents
        if let teacherPeer = rolesByPeer.first(where: { $0.value == .teacher })?.key {
            let message = Message(type: "students", role: nil, students: currentStudents, target: nil)
            if let data = try? JSONEncoder().encode(message) {
                try? session.send(data, toPeers: [teacherPeer], with: .reliable)
            }
        }
    }

    /// Clears stale connection flags for clients.
    /// Called on server start and periodically by the client list view.
    func refreshConnectedClients() {
        guard let context = modelContext else { return }
        let descriptor = FetchDescriptor<ClientInfo>(predicate: #Predicate { $0.isConnected })
        if let clients = try? context.fetch(descriptor) {
            let activeNames = Set(session.connectedPeers.map { $0.displayName })
            for client in clients where !activeNames.contains(client.deviceName) {
                client.isConnected = false
            }
            try? context.save()
        }
    }
}

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
            invitationHandler(true, self.session)
            if let context = self.modelContext {
                let name = peerID.displayName
                // Fetch all clients with the same device name and update the one matching the current course.
                let predicate = #Predicate<ClientInfo> { $0.deviceName == name }
                let descriptor = FetchDescriptor<ClientInfo>(predicate: predicate)
                let results = (try? context.fetch(descriptor)) ?? []
                let existing = results.first { $0.course?.persistentModelID == self.currentCourse?.persistentModelID }
                if let existing {
                    existing.nickname = payload?.nickname ?? existing.nickname
                    existing.role = self.rolesByPeer[peerID]?.rawValue ?? existing.role
                    existing.lastConnected = .now
                    existing.isConnected = true
                    existing.course = self.currentCourse
                } else {
                    let info = ClientInfo(deviceName: name,
                                          nickname: payload?.nickname ?? "",
                                          role: self.rolesByPeer[peerID]?.rawValue ?? "",
                                          ipAddress: nil,
                                          lastConnected: .now,
                                          isConnected: true,
                                          course: self.currentCourse)
                    context.insert(info)
                }
                try? context.save()
            }
        }
    }
}

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

extension PeerConnectionManager: MCSessionDelegate {
    nonisolated func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        Task { @MainActor in
            switch state {
            case .connected:
                self.connectionStatus = "Connected to \(peerID.displayName)"
                if self.advertiser == nil {
                    self.connectedServer = peerID
                }
                if let role = self.rolesByPeer[peerID] {
                    let message = Message(type: "role", role: role.rawValue, students: nil, target: nil)
                    if let data = try? JSONEncoder().encode(message) {
                        try? session.send(data, toPeers: [peerID], with: .reliable)
                    }
                }
                self.broadcastCurrentState(to: [peerID])
                self.updateStudents()
                if let context = self.modelContext {
                    let name = peerID.displayName
                    let predicate = #Predicate<ClientInfo> { $0.deviceName == name }
                    let descriptor = FetchDescriptor<ClientInfo>(predicate: predicate)
                    if let existing = try? context.fetch(descriptor).first {
                        existing.isConnected = true
                        existing.lastConnected = .now
                        try? context.save()
                    }
                }
            case .connecting:
                self.connectionStatus = "Connecting to \(peerID.displayName)..."
            case .notConnected:
                let actingAsClient = self.advertiser == nil
                self.connectionStatus = "Not Connected"
                self.rolesByPeer.removeValue(forKey: peerID)
                self.updateStudents()
                if actingAsClient {
                    if self.connectedServer == peerID {
                        self.connectedServer = nil
                    }
                    if self.userInitiatedDisconnect {
                        self.userInitiatedDisconnect = false
                    } else if self.myRole != nil {
                        // Lost connection to the server after a successful join.
                        self.serverDisconnected = true
                    }
                    self.myRole = nil
                } else {
                    self.userInitiatedDisconnect = false
                }
                if let context = self.modelContext {
                    let name = peerID.displayName
                    let predicate = #Predicate<ClientInfo> { $0.deviceName == name }
                    let descriptor = FetchDescriptor<ClientInfo>(predicate: predicate)
                    if let existing = try? context.fetch(descriptor).first {
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
            case "startClass":
                self.classStarted = true
                if self.advertiser != nil {
                    if let data = try? JSONEncoder().encode(message) {
                        try? session.send(data, toPeers: session.connectedPeers, with: .reliable)
                    }
                }
            case "disconnect":
                if let target = message.target {
                    if self.advertiser != nil {
                        self.disconnect(peerNamed: target)
                    }
                }
            case "endClass":
                self.serverDisconnected = true
                self.userInitiatedDisconnect = true
                self.session.disconnect()
                self.myRole = nil
            case "state":
                if let course = message.course {
                    self.currentCourse = Course(name: course.name, intro: course.intro, scheduledAt: course.scheduledAt)
                } else {
                    self.currentCourse = nil
                }
                if let lesson = message.lesson {
                    self.currentLesson = Lesson(title: lesson.title, number: 0, scheduledAt: lesson.scheduledAt, intro: lesson.intro)
                } else {
                    self.currentLesson = nil
                }
            default:
                break
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

