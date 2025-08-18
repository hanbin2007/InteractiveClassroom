import Combine
import Foundation

@MainActor
final class ServerConnectViewModel: ObservableObject {
    @Published var availablePeers: [PeerConnectionManager.Peer] = []
    @Published var connectionStatus: String = ""
    @Published var showError: Bool = false
    @Published private(set) var awaitingConnection: Bool = false

    private var cancellables = Set<AnyCancellable>()
    private var pairingService: PairingService?

    func bind(to service: PairingService) {
        guard pairingService == nil else { return }
        pairingService = service

        service.$availablePeers
            .receive(on: RunLoop.main)
            .assign(to: \.availablePeers, on: self)
            .store(in: &cancellables)

        service.$connectionStatus
            .receive(on: RunLoop.main)
            .sink { [weak self] status in
                guard let self else { return }
                self.connectionStatus = status
                if awaitingConnection {
                    if status == "Not Connected" {
                        self.showError = true
                        self.awaitingConnection = false
                    } else if status.contains("Connected") {
                        self.awaitingConnection = false
                    }
                }
            }
            .store(in: &cancellables)
    }

    func startBrowsing() {
        pairingService?.startBrowsing()
    }

    func stopBrowsing() {
        pairingService?.stopBrowsing()
    }

    func connect(to peer: PeerConnectionManager.Peer, passcode: String, nickname: String) {
        awaitingConnection = true
        pairingService?.connect(to: peer, passcode: passcode, nickname: nickname)
    }
}

