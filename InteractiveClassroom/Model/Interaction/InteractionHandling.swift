import Foundation

protocol InteractionHandling: AnyObject {
    func startInteraction(_ request: InteractionRequest, broadcast: Bool)
    func endInteraction(broadcast: Bool)
}
