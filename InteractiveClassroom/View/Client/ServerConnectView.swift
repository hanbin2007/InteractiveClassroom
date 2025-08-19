#if os(iOS)
import SwiftUI
import MultipeerConnectivity

struct ServerConnectView: View {
    @EnvironmentObject private var pairingService: PairingService
    @StateObject private var viewModel = ServerConnectViewModel()
    @State private var selectedPeer: PeerConnectionManager.Peer?
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
                    if pairingService.isConnected(to: peer) {
                        Image(systemName: "checkmark.circle")
                            .foregroundColor(.green)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    handlePeerTap(peer)
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    if pairingService.isConnected(to: peer) {
                        Button(role: .destructive) {
                            pairingService.disconnectFromServer()
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
            PasscodeEntrySheet(peer: peer) { passcode, nickname in
                viewModel.connect(to: peer, passcode: passcode, nickname: nickname)
            } onDismiss: {
                selectedPeer = nil
            }
        }
        .onAppear {
            viewModel.bind(to: pairingService)
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
                pairingService.disconnectFromServer()
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
        .onChange(of: pairingService.myRole) { _, role in
            if let role = role {
                navigateToTeacher = role == .teacher
                navigateToStudent = role == .student
            } else {
                navigateToTeacher = false
                navigateToStudent = false
            }
        }
        .onChange(of: pairingService.connectedServer) { _, server in
            if server == nil {
                navigateToTeacher = false
                navigateToStudent = false
            }
        }
        .onChange(of: pairingService.serverDisconnected) { _, disconnected in
            if disconnected {
                navigateToTeacher = false
                navigateToStudent = false
            }
        }
    }

    /// Handles taps on a server row, respecting existing connections.
    private func handlePeerTap(_ peer: PeerConnectionManager.Peer) {
        if pairingService.isConnected(to: peer) {
            if let role = pairingService.myRole {
                navigateToTeacher = role == .teacher
                navigateToStudent = role == .student
            }
        } else if pairingService.connectedServer != nil {
            pendingPeer = peer
            showDisconnectAlert = true
        } else {
            selectedPeer = peer
        }
    }

}

/// Sheet presented for entering a passcode and nickname when connecting to a server.
private struct PasscodeEntrySheet: View {
    let peer: PeerConnectionManager.Peer
    var connectAction: (String, String) -> Void
    var onDismiss: () -> Void

    @State private var passcode = ""
    @State private var nickname = ""
    @FocusState private var passcodeFocused: Bool

    var body: some View {
        NavigationStack {
                Form {
                    // 顶部说明
                    Section {
                        HStack(spacing: 12) {
                            Image(systemName: "lock.circle")
                                .font(.title2)
                                .foregroundStyle(.blue)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(peer.peerID.displayName)
                                    .font(.headline)
                                Text("Enter the 6-digit key to join")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .listRowBackground(Color.clear)
                    }

                    // 验证码
                    Section("Access Code") {
                        TextField("6-digit code", text: $passcode)
                            .keyboardType(.numberPad)
                            .textContentType(.oneTimeCode)
                            .font(.system(size: 28, weight: .semibold, design: .rounded))
                            .monospacedDigit()
                            .multilineTextAlignment(.center)
                            .focused($passcodeFocused)
                            .onChange(of: passcode) { _, newValue in
                                let digitsOnly = newValue.filter { $0.isNumber }
                                passcode = String(digitsOnly.prefix(6))
                            }
                    }

                    // 昵称
                    Section("Nickname") {
                        TextField("How should we call you?", text: $nickname)
                            .textInputAutocapitalization(.words)
                            .autocorrectionDisabled()
                    }
                }
                .formStyle(.grouped)
                .navigationTitle("Connect")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel", role: .cancel) {
                            onDismiss()
                        }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Connect") {
                            connectAction(
                                passcode,
                                nickname.trimmingCharacters(in: .whitespacesAndNewlines)
                            )
                            passcode = ""
                            nickname = ""
                            onDismiss()
                        }
                        .disabled(
                            passcode.count != 6 ||
                            nickname.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                        )
                    }
                    ToolbarItemGroup(placement: .keyboard) {
                        Spacer()
                        Button("Done") { passcodeFocused = false }
                    }
                }
                .scrollDismissesKeyboard(.interactively)
                .onAppear {
                    DispatchQueue.main.async { passcodeFocused = true }
                }
            }
            .presentationDetents([.medium])
    }
}
#Preview {
    NavigationStack {
        let pairing = PairingService()
        let interaction = InteractionService(manager: pairing)
        let courseService = CourseSessionService(manager: pairing, interactionService: interaction)
        ServerConnectView()
            .environmentObject(pairing)
            .environmentObject(courseService)
            .environmentObject(interaction)
    }
}
#endif
