import SwiftUI
import MultipeerConnectivity

#if os(iOS)
struct ServerConnectView: View {
    @EnvironmentObject private var connectionManager: PeerConnectionManager
    @StateObject private var viewModel = ServerConnectViewModel()
    @State private var selectedPeer: PeerConnectionManager.Peer?
    @State private var passcode: String = ""
    @State private var nickname: String = ""

    var body: some View {
        VStack {
            List(viewModel.availablePeers) { peer in
                Button(peer.peerID.displayName) {
                    selectedPeer = peer
                }
            }
            .overlay {
                if viewModel.availablePeers.isEmpty {
                    Text("Searching for servers...")
                        .foregroundStyle(.secondary)
                }
            }
            Text(viewModel.connectionStatus)
                .padding()
        }
        .navigationTitle("Select Server")
        .sheet(item: $selectedPeer) { peer in
            VStack(spacing: 16) {
                Text("Enter 6-digit key for \(peer.peerID.displayName)")
                TextField("123456", text: $passcode)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .multilineTextAlignment(.center)
                    .keyboardType(.numberPad)
                TextField("Nickname", text: $nickname)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .textInputAutocapitalization(.never)
                Button("Connect") {
                    viewModel.connect(to: peer, passcode: passcode, nickname: nickname)
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
        .onAppear {
            viewModel.bind(to: connectionManager)
            viewModel.startBrowsing()
        }
        .onDisappear { viewModel.stopBrowsing() }
        .alert("Connection Failed", isPresented: $viewModel.showError) {
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

