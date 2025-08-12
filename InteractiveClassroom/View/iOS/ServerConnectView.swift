import SwiftUI
import MultipeerConnectivity

#if os(iOS)
struct ServerConnectView: View {
    @EnvironmentObject private var connectionManager: PeerConnectionManager
    @State private var selectedPeer: PeerConnectionManager.Peer?
    @State private var passcode: String = ""
    @State private var nickname: String = ""
    @State private var showError: Bool = false
    @State private var awaitingConnection: Bool = false

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
                TextField("Nickname", text: $nickname)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .textInputAutocapitalization(.never)
                Button("Connect") {
                    awaitingConnection = true
                    connectionManager.connect(to: peer, passcode: passcode, nickname: nickname)
                    passcode = ""
                    nickname = ""
                    selectedPeer = nil
                }
                .disabled(passcode.isEmpty || nickname.isEmpty)
                Button("Cancel") {
                    selectedPeer = nil
                    passcode = ""
                    nickname = ""
                }
            }
            .padding()
            .presentationDetents([.medium])
        }
        .onAppear { connectionManager.startBrowsing() }
        .onDisappear { connectionManager.stopBrowsing() }
        .onChange(of: connectionManager.connectionStatus) { newValue in
            if awaitingConnection {
                if newValue == "Not Connected" {
                    showError = true
                    awaitingConnection = false
                } else if newValue.contains("Connected") {
                    awaitingConnection = false
                }
            }
        }
        .alert("Connection Failed", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Invalid key code or teacher already connected.")
        }
    }
}

#Preview {
    NavigationStack {
        ServerConnectView()
            .environmentObject(PeerConnectionManager())
    }
}
#endif

