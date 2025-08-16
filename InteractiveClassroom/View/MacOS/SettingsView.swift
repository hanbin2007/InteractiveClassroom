#if os(macOS)
import SwiftUI
import SwiftData

/// Settings for overlay appearance and behavior.
struct SettingsView: View {
    @EnvironmentObject private var connectionManager: PeerConnectionManager
    @Environment(\.modelContext) private var modelContext
    @AppStorage("overlayFontScale") private var overlayFontScale: Double = 1.0

    var body: some View {
        Form {
            Section("Overlay") {
                HStack {
                    Text("Font Scale")
                    Slider(value: $overlayFontScale, in: 0.5...2.0, step: 0.1)
                    Text("\(overlayFontScale, specifier: "%.1f")x")
                        .frame(width: 40, alignment: .trailing)
                }
            }
        }
        .padding(20)
        .frame(minWidth: 400, minHeight: 300)
        // Ensure the connection manager uses the same model context as the settings view
        .onAppear {
            connectionManager.modelContext = modelContext
        }
    }
}
#Preview {
    SettingsView()
        .environmentObject(PreviewSampleData.connectionManager)
        .modelContainer(PreviewSampleData.container)
}
#endif
