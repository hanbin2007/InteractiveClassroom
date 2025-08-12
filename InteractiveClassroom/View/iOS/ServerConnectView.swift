import SwiftUI
import MultipeerConnectivity

#if os(iOS)
struct ServerConnectView: View {
    @StateObject private var connectionManager = PeerConnectionManager()
    @State private var selectedPeer: PeerConnectionManager.Peer?
    @State private var passcode: String = ""

    var body: some View {
        VStack {
            List(connectionManager.availablePeers) { peer in
                Button(peer.peerID.displayName) {
                    selectedPeer = peer
                }
            }
            .overlay {
                if connectionManager.availablePeers.isEmpty {
                    Text("Searching for servers...")
                        .foregroundStyle(.secondary)
                }
            }
            Text(connectionManager.connectionStatus)
                .padding()
        }
        .navigationTitle("Select Server")
        .sheet(item: $selectedPeer) { peer in
            VStack(spacing: 16) {
                Text("Enter 6-digit key for \(peer.peerID.displayName)")
                TextField("123456", text: $passcode)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .multilineTextAlignment(TextAlignment.center)
                    .keyboardType(.numberPad)
                Button("Connect") {
                    connectionManager.connect(to: peer, passcode: passcode)
                    passcode = ""
                    selectedPeer = nil
                }
                Button("Cancel") {
                    selectedPeer = nil
                    passcode = ""
                }
            }
            .padding()
            .presentationDetents([.medium])
        }
        .onAppear {
            connectionManager.startBrowsing()
        }
        .onDisappear {
            connectionManager.stopBrowsing()
        }
    }
}

#Preview {
    NavigationStack {
        ServerConnectView()
    }
}
#endif

