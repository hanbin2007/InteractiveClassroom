#if os(iOS)
import SwiftUI

struct TeacherDashboardView: View {
    @EnvironmentObject private var courseSessionService: CourseSessionService
    @EnvironmentObject private var pairingService: PairingService
    @StateObject private var viewModel = TeacherDashboardViewModel()
    @State private var selectedTab = 0
    @State private var showStartPopover = false

    private let tabs = [
        TabItem(icon: "person.3.fill", title: "Students"),
        TabItem(icon: "book.closed.fill", title: "Lessons"),
        TabItem(icon: "gearshape.fill", title: "Settings"),
        TabItem(icon: "chart.bar.xaxis", title: "Reports"),
        TabItem(icon: "questionmark.circle", title: "Help"),
        TabItem(icon: "list.bullet.rectangle", title: "Quiz")
    ]

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $selectedTab) {
                studentsView.tag(0)
                placeholder("Lessons").tag(1)
                placeholder("Settings").tag(2)
                placeholder("Reports").tag(3)
                placeholder("Help").tag(4)
                MultipleChoiceSetupView().tag(5)
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))

            CustomTabView(tabs: tabs, selection: $selectedTab)
        }
        .navigationTitle("Teacher")
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                Button {
                    showStartPopover = true
                } label: {
                    Image(systemName: "play.fill")
                    Text("Start Class").bold()
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)
                .popover(isPresented: $showStartPopover, attachmentAnchor: .point(.bottom), arrowEdge: .bottom) {
                    StartClassPopoverView { date in
                        viewModel.startClass(at: date)
                    }
                }
                
                Button {
                    pairingService.disconnectFromServer()
                } label: {
                    Image(systemName: "personalhotspot.slash")
                }
                .accessibilityLabel("Disconnect")
            }
        }
        .onAppear { viewModel.bind(to: courseSessionService) }
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
    let pairing = PairingService()
    pairing.students = ["Alice", "Bob"]
    let interaction = InteractionService(manager: pairing)
    let courseService = CourseSessionService(manager: pairing, interactionService: interaction)
    return NavigationStack { TeacherDashboardView() }
        .environmentObject(courseService)
        .environmentObject(pairing)
        .environmentObject(interaction)
}

#endif
