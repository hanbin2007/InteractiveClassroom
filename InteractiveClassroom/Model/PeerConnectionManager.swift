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

    @Published var availablePeers: [MCPeerID] = []
    @Published var connectionStatus: String = "Not Connected"
    @Published var hostCode: String?

    override init() {
#if os(macOS)
        myPeerID = MCPeerID(displayName: Host.current()?.localizedName ?? "macOS")
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

    func connect(to peer: MCPeerID, passcode: String) {
        let context = passcode.data(using: .utf8)
        browser?.invitePeer(peer, to: session, withContext: context, timeout: 30)
    }
}

extension PeerConnectionManager: MCNearbyServiceAdvertiserDelegate {
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        let code = context.flatMap { String(data: $0, encoding: .utf8) }
        if code == hostCode {
            invitationHandler(true, session)
        } else {
            invitationHandler(false, nil)
        }
    }
}

extension PeerConnectionManager: MCNearbyServiceBrowserDelegate {
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        if !availablePeers.contains(peerID) {
            availablePeers.append(peerID)
        }
    }

    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        availablePeers.removeAll { $0 == peerID }
    }
}

extension PeerConnectionManager: MCSessionDelegate {
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        switch state {
        case .connected:
            connectionStatus = "Connected to \(peerID.displayName)"
        case .connecting:
            connectionStatus = "Connecting to \(peerID.displayName)..."
        case .notConnected:
            connectionStatus = "Not Connected"
        @unknown default:
            connectionStatus = "Unknown State"
        }
    }

    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {}
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {}
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {}
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {}
    func session(_ session: MCSession, didReceiveCertificate certificate: [Any]?, fromPeer peerID: MCPeerID, certificateHandler: @escaping (Bool) -> Void) { certificateHandler(true) }
}

extension MCPeerID: Identifiable {
    public var id: String { displayName }
}

