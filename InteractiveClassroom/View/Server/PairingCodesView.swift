#if os(macOS)
import SwiftUI

struct PairingCodesView: View {
    @EnvironmentObject private var pairingService: PairingService
    @StateObject private var viewModel = PairingCodesViewModel()

    var body: some View {
        VStack(spacing: 16) {
            if let teacher = viewModel.teacherCode,
               let student = viewModel.studentCode {
                codeBlock(title: "Teacher Code", code: teacher)
                codeBlock(title: "Student Code", code: student)
            } else {
                Text("Classroom not opened")
                    .font(.headline)
            }
        }
        .padding(24)
        .frame(minWidth: 240)
        .onAppear {
            viewModel.bind(to: pairingService)
        }
    }

    @ViewBuilder
    private func codeBlock(title: String, code: String) -> some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.headline)
            Text(code)
                .font(.largeTitle)
                .fontWeight(.bold)
                .monospacedDigit()
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    let pairing = PairingService()
    pairing.teacherCode = "123456"
    pairing.studentCode = "654321"
    return PairingCodesView()
        .environmentObject(pairing)
}
#endif
