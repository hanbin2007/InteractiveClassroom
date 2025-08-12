import SwiftUI
import MultipeerConnectivity

struct ServerConnectView: View {
    @StateObject private var connectionManager = PeerConnectionManager()
    @State private var selectedPeer: MCPeerID?
    @State private var passcode: String = ""

    var body: some View {
        VStack {
            List(connectionManager.availablePeers, id: \.self) { peer in
                Button(peer.displayName) {
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
                Text("Enter 6-digit key for \(peer.displayName)")
                TextField("123456", text: $passcode)
                    .keyboardType(.numberPad)
                    .textFieldStyle(.roundedBorder)
                    .multilineTextAlignment(.center)
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

