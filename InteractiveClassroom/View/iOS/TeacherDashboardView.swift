import SwiftUI

#if os(iOS)
struct TeacherDashboardView: View {
    @EnvironmentObject private var connectionManager: PeerConnectionManager

    var body: some View {
        VStack {
            List(connectionManager.students, id: \.self) { student in
                HStack {
                    Text(student)
                    Spacer()
                    Button("Disconnect") {
                        connectionManager.sendDisconnectCommand(for: student)
                    }
                }
            }
            Button("Start Class") {
                connectionManager.startClass()
            }
            .padding()
        }
        .navigationTitle("Teacher")
    }
}
#Preview {
    let manager = PeerConnectionManager()
    manager.students = ["Alice", "Bob"]
    return NavigationStack { TeacherDashboardView() }
        .environmentObject(manager)
}
#endif
