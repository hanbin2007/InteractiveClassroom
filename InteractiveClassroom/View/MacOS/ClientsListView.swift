#if os(macOS)
import SwiftUI
import SwiftData

/// Displays a table of connected clients and allows disconnection.
struct ClientsListView: View {
    @EnvironmentObject private var connectionManager: PeerConnectionManager
    @Environment(\.modelContext) private var modelContext
    // Fetch clients ordered by most recent connection and animate updates for timely refreshes.
    @Query(sort: \ClientInfo.lastConnected, order: .reverse, animation: .default) private var allClients: [ClientInfo]
    /// Timer used to periodically refresh connection status.
    @State private var refreshTimer = Timer.publish(every: 5, on: .main, in: .common).autoconnect()
    private var clients: [ClientInfo] {
        allClients.filter { $0.course?.persistentModelID == connectionManager.currentCourse?.persistentModelID }
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading) {
                if connectionManager.currentCourse == nil {
                    Text("Please select a course")
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                        .padding()
                } else if clients.isEmpty {
                    Text("No clients connected")
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                        .padding()
                } else {
                    Table(clients) {
                        TableColumn("Status") { client in
                            Circle()
                                .fill(client.isConnected ? Color.green : Color.red)
                                .frame(width: 8, height: 8)
                        }
                        TableColumn("Device") { client in
                            Text(client.deviceName)
                        }
                        TableColumn("Nickname") { client in
                            Text(client.nickname)
                        }
                        TableColumn("Role") { client in
                            Text(client.role)
                        }
                        TableColumn("IP") { client in
                            Text(client.ipAddress ?? "N/A")
                        }
                        TableColumn("Last Connected") { client in
                            Text(client.lastConnected, format: Date.FormatStyle(date: .numeric, time: .standard))
                        }
                        TableColumn("") { client in
                            if client.isConnected {
                                Button("Disconnect") {
                                    connectionManager.disconnect(peerNamed: client.deviceName)
                                    client.isConnected = false
                                    try? modelContext.save()
                                }
                            }
                        }
                    }
                    .frame(minHeight: 300)
                }
            }
            .padding()
            .frame(minWidth: 600, minHeight: 400)
            .navigationTitle("Connected Clients")
        }
        // Refresh connected client state every five seconds.
        .onReceive(refreshTimer) { _ in
            connectionManager.refreshConnectedClients()
        }
        .onAppear {
            connectionManager.refreshConnectedClients()
        }
        .onDisappear {
            refreshTimer.upstream.connect().cancel()
        }
    }
}
#Preview {
    ClientsListView()
        .environmentObject({
            let manager = PeerConnectionManager()
            manager.currentCourse = Course(name: "Preview Course")
            return manager
        }())
        .modelContainer(for: [ClientInfo.self, Course.self, Lesson.self], inMemory: true)
}
#endif
