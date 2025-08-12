import Foundation
import MultipeerConnectivity
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

    struct Peer: Identifiable, Hashable {
        let peerID: MCPeerID
        var id: String { peerID.displayName }
    }

    @Published var availablePeers: [Peer] = []
    @Published var connectionStatus: String = "Not Connected"
    @Published var hostCode: String?

    override init() {
#if os(macOS)
        myPeerID = MCPeerID(displayName: Host.current().localizedName ?? "macOS")
#else
        myPeerID = MCPeerID(displayName: UIDevice.current.name)
#endif
        session = MCSession(peer: myPeerID, securityIdentity: nil, encryptionPreference: .required)
        super.init()
        session.delegate = self
    }

    func startHosting() {
        hostCode = String(format: "%06d", Int.random(in: 0..<1_000_000))
        advertiser = MCNearbyServiceAdvertiser(peer: myPeerID, discoveryInfo: nil, serviceType: serviceType)
        advertiser?.delegate = self
        advertiser?.startAdvertisingPeer()
        connectionStatus = "Awaiting connection..."
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

    func connect(to peer: Peer, passcode: String) {
        let context = passcode.data(using: .utf8)
        browser?.invitePeer(peer.peerID, to: session, withContext: context, timeout: 30)
    }
}

extension PeerConnectionManager: MCNearbyServiceAdvertiserDelegate {
    nonisolated func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        let code = context.flatMap { String(data: $0, encoding: .utf8) }
        Task { @MainActor in
            if code == self.hostCode {
                invitationHandler(true, self.session)
            } else {
                invitationHandler(false, nil)
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
            case .connecting:
                self.connectionStatus = "Connecting to \(peerID.displayName)..."
            case .notConnected:
                self.connectionStatus = "Not Connected"
            @unknown default:
                self.connectionStatus = "Unknown State"
            }
        }
    }

    nonisolated func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {}
    nonisolated func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {}
    nonisolated func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {}
    nonisolated func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {}
    nonisolated func session(_ session: MCSession, didReceiveCertificate certificate: [Any]?, fromPeer peerID: MCPeerID, certificateHandler: @escaping (Bool) -> Void) {
        certificateHandler(true)
    }
}

