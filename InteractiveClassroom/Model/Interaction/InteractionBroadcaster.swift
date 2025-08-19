import Foundation
import MultipeerConnectivity

// MARK: - Broadcasting Helpers
extension InteractionService {
    /// Sends a start interaction message to the server.
    func broadcastStartInteraction(_ request: InteractionRequest, remainingSeconds: Int?, stageIndex: Int) {
        let remaining = remainingSeconds ?? currentRemainingSeconds()
        let message = PeerConnectionManager.Message(
            type: "startInteraction",
            interaction: request,
            remainingSeconds: remaining,
            stageIndex: stageIndex
        )
        manager.sendMessageToServer(message)
    }

    /// Sends a stop interaction message to the server.
    func broadcastStopInteraction() {
        let message = PeerConnectionManager.Message(type: "stopInteraction", interaction: nil)
        manager.sendMessageToServer(message)
        print("[InteractionService] Sent stop interaction message to server.")
    }

    /// Sends a next stage message to the server.
    func broadcastNextStage(_ stageIndex: Int) {
        let message = PeerConnectionManager.Message(type: "nextStage", interaction: nil, stageIndex: stageIndex)
        manager.sendMessageToServer(message)
    }
}
