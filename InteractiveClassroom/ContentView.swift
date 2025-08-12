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

    var body: some View {
        Group {
            if let role = connectionManager.myRole {
                switch role {
                case .teacher:
                    NavigationStack { TeacherDashboardView() }
                case .student:
                    NavigationStack { StudentWaitingView() }
                default:
                    Text("Unsupported role")
                }
            } else {
                NavigationStack { ServerConnectView() }
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(PeerConnectionManager())
}
#endif
