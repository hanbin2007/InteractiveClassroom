#if os(iOS)
import SwiftUI
import MultipeerConnectivity

struct ServerConnectView: View {
    @EnvironmentObject private var connectionManager: PeerConnectionManager
    @StateObject private var viewModel = ServerConnectViewModel()
    @State private var selectedPeer: PeerConnectionManager.Peer?
    @State private var passcode: String = ""
    @State private var nickname: String = ""
    @State private var navigateToTeacher = false
    @State private var navigateToStudent = false
    @State private var pendingPeer: PeerConnectionManager.Peer?
    @State private var showDisconnectAlert = false

    var body: some View {
        VStack {
            List(viewModel.availablePeers) { peer in
                HStack {
                    Text(peer.peerID.displayName)
                    Spacer()
                    if connectionManager.isConnected(to: peer) {
                        Image(systemName: "checkmark.circle")
                            .foregroundColor(.green)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    handlePeerTap(peer)
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    if connectionManager.isConnected(to: peer) {
                        Button(role: .destructive) {
                            connectionManager.disconnectFromServer()
                            navigateToTeacher = false
                            navigateToStudent = false
                        } label: {
                            Label("Disconnect", systemImage: "personalhotspot.slash")
                        }
                    }
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
        // Navigation destinations for assigned roles
        .navigationDestination(isPresented: $navigateToTeacher) {
            TeacherDashboardView()
        }
        .navigationDestination(isPresented: $navigateToStudent) {
            StudentWaitingView()
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
        .onChange(of: selectedPeer) { _, peer in
            if peer != nil {
                viewModel.stopBrowsing()
            } else {
                viewModel.startBrowsing()
            }
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
        .alert("Disconnect from current server?", isPresented: $showDisconnectAlert) {
            Button("Cancel", role: .cancel) { pendingPeer = nil }
            Button("Disconnect", role: .destructive) {
                connectionManager.disconnectFromServer()
                if let peer = pendingPeer {
                    // Delay presenting passcode sheet to allow disconnect to settle
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        selectedPeer = peer
                    }
                }
                pendingPeer = nil
            }
        } message: {
            Text("You are currently connected. Disconnect to join another server?")
        }
        .onChange(of: connectionManager.myRole) { _, role in
            if let role = role {
                navigateToTeacher = role == .teacher
                navigateToStudent = role == .student
            } else {
                navigateToTeacher = false
                navigateToStudent = false
            }
        }
        .onChange(of: connectionManager.connectedServer) { _, server in
            if server == nil {
                navigateToTeacher = false
                navigateToStudent = false
            }
        }
        .onChange(of: connectionManager.serverDisconnected) { _, disconnected in
            if disconnected {
                navigateToTeacher = false
                navigateToStudent = false
                selectedPeer = nil
                passcode = ""
                nickname = ""
                viewModel.startBrowsing()
            }
        }
    }

    /// Handles taps on a server row, respecting existing connections.
    private func handlePeerTap(_ peer: PeerConnectionManager.Peer) {
        if connectionManager.isConnected(to: peer) {
            if let role = connectionManager.myRole {
                navigateToTeacher = role == .teacher
                navigateToStudent = role == .student
            }
        } else if connectionManager.connectedServer != nil {
            pendingPeer = peer
            showDisconnectAlert = true
        } else {
            selectedPeer = peer
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
