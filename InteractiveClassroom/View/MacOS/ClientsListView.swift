#if os(macOS)
import SwiftUI
import SwiftData

/// Displays a table of connected clients and allows disconnection.
struct ClientsListView: View {
    @EnvironmentObject private var connectionManager: PeerConnectionManager
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ClientInfo.lastConnected, order: .reverse) private var clients: [ClientInfo]

    var body: some View {
        VStack(alignment: .leading) {
            Text("Connected Clients")
                .font(.title2)
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
        .padding()
        .frame(minWidth: 600, minHeight: 400)
    }
}
#endif
