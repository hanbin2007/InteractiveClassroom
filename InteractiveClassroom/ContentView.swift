//
//  ContentView.swift
//  InteractiveClassroom
//
//  Created by zhb on 2025/8/12.
//

import SwiftUI

#if os(iOS)
/// Root view used on iOS and iPadOS to select and present the desired role.
struct ContentView: View {
    @State private var selectedRole: UserRole? = nil

    var body: some View {
        Group {
            if let role = selectedRole {
                switch role {
                case .screen:
                    Text("Screen mode is available on macOS menu bar.")
                        .padding()
                case .teacher:
                    NavigationStack {
                        ServerConnectView()
                    }
                case .student:
                    NavigationStack {
                        ServerConnectView()
                    }
                }
            } else {
                IdentitySelectionView(selection: $selectedRole)
            }
        }
    }
}

#Preview {
    ContentView()
}
#endif
