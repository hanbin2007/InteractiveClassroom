#if os(macOS)
import SwiftUI
import SwiftData

/// Settings used to configure how questions are presented and scored.
struct SettingsView: View {
    @EnvironmentObject private var connectionManager: PeerConnectionManager
    @Environment(\.modelContext) private var modelContext
    @State private var timeLimit: Int = 60
    @State private var correctAnswer: String = ""
    @State private var anonymous: Bool = false
    @State private var shuffleOptions: Bool = false
    @State private var allowModification: Bool = true
    @State private var score: Int = 1
    @AppStorage("overlayFontScale") private var overlayFontScale: Double = 1.0

    var body: some View {
        Form {
            Section("Connection") {
                if let t = connectionManager.teacherCode, let s = connectionManager.studentCode {
                    Text("Teacher Key: \(t)")
                    Text("Student Key: \(s)")
                }
                Text(connectionManager.connectionStatus)
            }
            Section("Question") {
                Stepper(value: $timeLimit, in: 10...3600, step: 10) {
                    Text("Time Limit: \(timeLimit) s")
                }
                TextField("Correct Answer", text: $correctAnswer)
                Toggle("Anonymous", isOn: $anonymous)
                Toggle("Shuffle Options", isOn: $shuffleOptions)
                Toggle("Allow Answer Changes", isOn: $allowModification)
                Stepper(value: $score, in: 1...100) {
                    Text("Score: \(score)")
                }
            }
            Section("Export") {
                Button("Export Results") {}
            }
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
    let manager = PeerConnectionManager()
    manager.teacherCode = "123456"
    manager.studentCode = "654321"
    let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: [ClientInfo.self, Course.self, Lesson.self], configurations: configuration)
    SettingsView()
        .environmentObject(manager)
        .modelContainer(container)
}
#endif
