//
//  ContentView.swift
//  InteractiveClassroom
//
//  Created by zhb on 2025/8/12.
//

import SwiftUI

#if os(iOS)
/// Root view for iOS and iPadOS clients.
struct ContentView: View {
    @EnvironmentObject private var pairingService: PairingService
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        NavigationStack {
            ServerConnectView()
        }
        .alert("Disconnected", isPresented: $pairingService.serverDisconnected) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Connection to server lost.")
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .background, pairingService.myRole != nil {
                pairingService.disconnectFromServer()
            }
        }
    }
}

#Preview {
    let manager = PeerConnectionManager()
    let pairing = PairingService(manager: manager)
    return ContentView()
        .environmentObject(pairing)
}
#endif
