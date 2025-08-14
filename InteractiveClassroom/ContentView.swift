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
    @EnvironmentObject private var connectionManager: PeerConnectionManager
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        NavigationStack {
            ServerConnectView()
        }
        .alert("Disconnected", isPresented: $connectionManager.serverDisconnected) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Connection to server lost.")
        }
        .onChange(of: scenePhase) { phase in
            if phase == .background, connectionManager.myRole != nil {
                connectionManager.disconnectFromServer()
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(PeerConnectionManager())
}
#endif
