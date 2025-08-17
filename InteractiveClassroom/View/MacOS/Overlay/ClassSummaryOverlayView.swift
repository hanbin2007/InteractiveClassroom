#if os(macOS)
import SwiftUI

/// Overlay displaying the list of currently online students during class summary.
struct ClassSummaryOverlayView: View {
    @EnvironmentObject private var connectionManager: PeerConnectionManager

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color.blue.opacity(0.6), Color.purple.opacity(0.6)],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
                .background(.ultraThinMaterial)
                .ignoresSafeArea()

            if connectionManager.showClassSummary {
                VStack(spacing: 24) {
                    Text("Class Summary")
                        .font(.largeTitle)
                        .bold()
                    let list = connectionManager.students
                    if list.isEmpty {
                        Text("No students connected")
                            .font(.title2)
                            .foregroundStyle(.secondary)
                            .transition(.opacity)
                    } else {
                        VStack(spacing: 16) {
                            ForEach(list, id: \.self) { name in
                                Text(name)
                                    .font(.title2)
                                    .transition(.move(edge: .bottom).combined(with: .opacity))
                            }
                        }
                        .animation(.easeInOut, value: list)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                .foregroundColor(.white)
                .transition(.scale.combined(with: .opacity))
            }

            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button {
                        withAnimation { connectionManager.toggleSummaryVisibility() }
                    } label: {
                        Image(systemName: connectionManager.showClassSummary ? "eye.slash" : "eye")
                            .padding(12)
                            .background(Color.black.opacity(0.4))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .padding()
                    .accessibilityLabel(connectionManager.showClassSummary ? "Hide Summary" : "Show Summary")
                }
            }
        }
        .animation(.easeInOut, value: connectionManager.showClassSummary)
    }
}
#endif
