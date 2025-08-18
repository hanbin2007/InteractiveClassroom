import Foundation
import Combine
import MultipeerConnectivity

@MainActor
final class PairingService: ObservableObject {
    @Published private(set) var availablePeers: [PeerConnectionManager.Peer] = []
    @Published private(set) var connectionStatus: String = "Not Connected"
    @Published private(set) var teacherCode: String?
    @Published private(set) var studentCode: String?
    @Published private(set) var myRole: UserRole?
    @Published private(set) var connectedServer: MCPeerID?
    @Published var serverDisconnected: Bool = false

    private let manager: PeerConnectionManager
    private var cancellables: Set<AnyCancellable> = []

    init(manager: PeerConnectionManager) {
        self.manager = manager

        manager.$availablePeers
            .receive(on: RunLoop.main)
            .sink { [weak self] in self?.availablePeers = $0 }
            .store(in: &cancellables)
        manager.$connectionStatus
            .receive(on: RunLoop.main)
            .sink { [weak self] in self?.connectionStatus = $0 }
            .store(in: &cancellables)
        manager.$teacherCode
            .receive(on: RunLoop.main)
            .sink { [weak self] in self?.teacherCode = $0 }
            .store(in: &cancellables)
        manager.$studentCode
            .receive(on: RunLoop.main)
            .sink { [weak self] in self?.studentCode = $0 }
            .store(in: &cancellables)
        manager.$myRole
            .receive(on: RunLoop.main)
            .sink { [weak self] in self?.myRole = $0 }
            .store(in: &cancellables)
        manager.$connectedServer
            .receive(on: RunLoop.main)
            .sink { [weak self] in self?.connectedServer = $0 }
            .store(in: &cancellables)
        manager.$serverDisconnected
            .receive(on: RunLoop.main)
            .sink { [weak self] in self?.serverDisconnected = $0 }
            .store(in: &cancellables)
    }

    // MARK: - Pairing Operations

    func openClassroom() { manager.openClassroom() }
    func startBrowsing() { manager.startBrowsing() }
    func stopBrowsing() { manager.stopBrowsing() }
    func connect(to peer: PeerConnectionManager.Peer, passcode: String, nickname: String) {
        manager.connect(to: peer, passcode: passcode, nickname: nickname)
    }
    func disconnectFromServer() { manager.disconnectFromServer() }
    func isConnected(to peer: PeerConnectionManager.Peer) -> Bool { manager.isConnected(to: peer) }
}
