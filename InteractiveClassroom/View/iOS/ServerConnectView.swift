import SwiftUI
import MultipeerConnectivity

#if os(iOS)
struct ServerConnectView: View {
    @EnvironmentObject private var connectionManager: PeerConnectionManager
    @StateObject private var viewModel = ServerConnectViewModel()
    @State private var selectedPeer: PeerConnectionManager.Peer?
    @State private var passcode: String = ""
    @State private var nickname: String = ""
    @State private var navigateToTeacher = false
    @State private var navigateToStudent = false

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
            NavigationLink(destination: TeacherDashboardView(), isActive: $navigateToTeacher) {
                EmptyView()
            }
            .hidden()
            .accessibilityHidden(true)
            NavigationLink(destination: StudentWaitingView(), isActive: $navigateToStudent) {
                EmptyView()
            }
            .hidden()
            .accessibilityHidden(true)
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
            if let role = connectionManager.myRole {
                navigateToTeacher = role == .teacher
                navigateToStudent = role == .student
            }
        }
        .onDisappear { viewModel.stopBrowsing() }
        .alert("Connection Failed", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Invalid key code or teacher already connected.")
        }
        .onChange(of: connectionManager.myRole) { role in
            navigateToTeacher = role == .teacher
            navigateToStudent = role == .student
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

