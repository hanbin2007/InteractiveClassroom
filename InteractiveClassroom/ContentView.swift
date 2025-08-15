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
    @State private var navigationID = UUID()

    var body: some View {
        NavigationStack {
            ServerConnectView()
        }
        .id(navigationID)
        .alert("Disconnected", isPresented: $connectionManager.serverDisconnected) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Connection to server lost.")
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .background, connectionManager.myRole != nil {
                connectionManager.disconnectFromServer()
            }
        }
        .onChange(of: connectionManager.connectedServer) { _, server in
            if server == nil {
                navigationID = UUID()
            }
        }
        .onChange(of: connectionManager.serverDisconnected) { _, disconnected in
            if disconnected {
                navigationID = UUID()
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(PeerConnectionManager())
}
#endif
