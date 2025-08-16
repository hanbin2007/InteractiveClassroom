import Combine
import Foundation

@MainActor
final class TeacherDashboardViewModel: ObservableObject {
    @Published var students: [String] = []

    private var cancellables = Set<AnyCancellable>()
    private var connectionManager: PeerConnectionManager?

    func bind(to manager: PeerConnectionManager) {
        guard connectionManager == nil else { return }
        connectionManager = manager

        manager.$students
            .receive(on: RunLoop.main)
            .assign(to: \.students, on: self)
            .store(in: &cancellables)

        manager.requestStudentList()
    }

    func sendDisconnect(for student: String) {
        connectionManager?.sendDisconnectCommand(for: student)
    }

    func startClass() {
        connectionManager?.startClass()
    }

    func summarizeClass() {
        connectionManager?.summarizeClass()
    }
}

