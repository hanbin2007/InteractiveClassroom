import Foundation
import MultipeerConnectivity
import SwiftData

@MainActor
final class PairingService: PeerConnectionManager {
    override init(modelContext: ModelContext? = nil, currentCourse: Course? = nil, currentLesson: Lesson? = nil) {
        super.init(modelContext: modelContext, currentCourse: currentCourse, currentLesson: currentLesson)
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
        setConnectedServer(nil)
    }

    override func disconnectPeer(named name: String) {
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

    private func refreshConnectedClients() {
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

