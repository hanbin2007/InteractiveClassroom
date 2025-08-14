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
                    Button("Disconnect") {
                        viewModel.sendDisconnect(for: student)
                    }
                }
            }
            Button("Start Class") {
                viewModel.startClass()
            }
            .padding()
        }
        .navigationTitle("Teacher")
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
