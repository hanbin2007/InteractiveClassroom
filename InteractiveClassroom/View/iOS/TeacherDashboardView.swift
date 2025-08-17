#if os(iOS)
import SwiftUI

struct TeacherDashboardView: View {
    @EnvironmentObject private var connectionManager: PeerConnectionManager
    @StateObject private var viewModel = TeacherDashboardViewModel()
    @State private var selectedTab = 0

    private let tabs = [
        TabItem(icon: "person.3.fill", title: "Students"),
        TabItem(icon: "book.closed.fill", title: "Lessons"),
        TabItem(icon: "gearshape.fill", title: "Settings"),
        TabItem(icon: "chart.bar.xaxis", title: "Reports"),
        TabItem(icon: "questionmark.circle", title: "Help")
    ]

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $selectedTab) {
                studentsView.tag(0)
                placeholder("Lessons").tag(1)
                placeholder("Settings").tag(2)
                placeholder("Reports").tag(3)
                placeholder("Help").tag(4)
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))

            CustomTabView(tabs: tabs, selection: $selectedTab)
        }
        .navigationTitle("Teacher")
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                if connectionManager.classStarted {
                    if let interaction = connectionManager.activeInteraction, interaction == .classSummary {
                        HStack(spacing: 8) {
                            Button {
                                viewModel.toggleInteractionVisibility()
                            } label: {
                                Image(systemName: connectionManager.interactionVisible ? "eye.slash" : "eye")
                                Text(connectionManager.interactionVisible ? "Hide Summary" : "Show Summary").bold()
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.yellow)

                            Button {
                                viewModel.endClass()
                            } label: {
                                Image(systemName: "stop.fill")
                                Text("End Class").bold()
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.red)
                        }
                    } else {
                        Button {
                            viewModel.startClassSummary()
                        } label: {
                            Image(systemName: "doc.text")
                            Text("Class Summarize").bold()
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.yellow)
                    }
                } else {
                    Button {
                        viewModel.startClass()
                    } label: {
                        Image(systemName: "play.fill")
                        Text("Start Class").bold()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.green)
                }

                Button {
                    connectionManager.disconnectFromServer()
                } label: {
                    Image(systemName: "personalhotspot.slash")
                }
                .accessibilityLabel("Disconnect")
            }
        }
        .onAppear { viewModel.bind(to: connectionManager) }
    }

    private var studentsView: some View {
        List {
            ForEach(viewModel.students, id: \.self) { student in
                HStack {
                    Text(student)
                    Spacer()
                    Button {
                        viewModel.sendDisconnect(for: student)
                    } label: {
                        Image(systemName: "personalhotspot.slash")
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Disconnect Student")
                }
            }
        }
        .overlay {
            if viewModel.students.isEmpty {
                Text("No students connected")
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func placeholder(_ title: String) -> some View {
        Text(title)
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
