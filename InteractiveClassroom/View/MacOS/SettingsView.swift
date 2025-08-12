#if os(macOS)
import SwiftUI

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
        }
        .padding(20)
        .frame(minWidth: 400, minHeight: 300)
        .onAppear {
            connectionManager.modelContext = modelContext
            connectionManager.startHosting()
        }
    }
}
#endif
