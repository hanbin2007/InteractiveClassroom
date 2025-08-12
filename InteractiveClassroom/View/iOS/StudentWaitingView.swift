import SwiftUI

#if os(iOS)
struct StudentWaitingView: View {
    @EnvironmentObject private var connectionManager: PeerConnectionManager

    var body: some View {
        VStack {
            if connectionManager.classStarted {
                Text("Class has started.")
            } else {
                Text("Waiting for the teacher to start the class...")
                    .multilineTextAlignment(.center)
                    .padding()
            }
        }
        .navigationTitle("Waiting")
    }
}
#endif
