import Foundation
import MultipeerConnectivity

protocol InteractionHandling: AnyObject {
    func startInteraction(_ request: InteractionRequest, broadcast: Bool)
    func endInteraction(broadcast: Bool)
    func broadcastCurrentState(to peers: [MCPeerID]?)
    func handleInteractionMessage(_ message: PeerConnectionManager.Message, from peerID: MCPeerID, session: MCSession)
}
