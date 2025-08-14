import SwiftUI

#if os(iOS)
struct TeacherDashboardView: View {
    @EnvironmentObject private var connectionManager: PeerConnectionManager
    @StateObject private var viewModel = TeacherDashboardViewModel()

    var body: some View {
        VStack {
            List(viewModel.students, id: \.self) { student in
                HStack {
                    Text(student)
                    Spacer()
                    Button {
                        viewModel.sendDisconnect(for: student)
                    } label: {
                        Image(systemName: "xmark.circle")
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Disconnect Student")
                }
            }
            Button("Start Class") {
                viewModel.startClass()
            }
            .padding()
        }
        .navigationTitle("Teacher")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    connectionManager.disconnectFromServer()
                } label: {
                    Image(systemName: "xmark.circle")
                }
                .accessibilityLabel("Disconnect")
            }
        }
        .onAppear { viewModel.bind(to: connectionManager) }
    }
}
#Preview {
    NavigationStack { TeacherDashboardView() }
        .environmentObject({
            let manager = PeerConnectionManager()
            manager.students = ["Alice", "Bob"]
            return manager
        }())
}
#endif
