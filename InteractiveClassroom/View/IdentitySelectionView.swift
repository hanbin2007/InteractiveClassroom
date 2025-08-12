import SwiftUI

/// Initial view that lets the user choose the role.
/// The available roles depend on the platform the app is running on.
struct IdentitySelectionView: View {
    @Binding var selection: UserRole?

    var body: some View {
        VStack(spacing: 24) {
            Text("Select Your Role")
                .font(.title2)
                .padding(.bottom, 8)
#if os(macOS)
            Button("Screen") { selection = .screen }
                .buttonStyle(.borderedProminent)
            Button("Teacher (iOS only)") {}
                .disabled(true)
            Button("Student (iOS only)") {}
                .disabled(true)
#else
            Button("Screen (macOS only)") {}
                .disabled(true)
            Button("Teacher") { selection = .teacher }
                .buttonStyle(.borderedProminent)
            Button("Student") { selection = .student }
                .buttonStyle(.borderedProminent)
#endif
        }
        .padding()
    }
}

#Preview {
    IdentitySelectionView(selection: .constant(nil))
}
