//
//  ContentView.swift
//  InteractiveClassroom
//
//  Created by zhb on 2025/8/12.
//

import SwiftUI

/// Root view used on iOS/iPadOS to select and present the desired role.
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
                    Text("Teacher view placeholder")
                        .padding()
                case .student:
                    Text("Student view placeholder")
                        .padding()
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
