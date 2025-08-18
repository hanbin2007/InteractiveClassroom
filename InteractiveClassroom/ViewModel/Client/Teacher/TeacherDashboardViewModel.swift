import Combine
import Foundation

@MainActor
final class TeacherDashboardViewModel: ObservableObject {
    @Published var students: [String] = []

    private var cancellables = Set<AnyCancellable>()
    private var service: CourseSessionService?

    func bind(to service: CourseSessionService) {
        guard self.service == nil else { return }
        self.service = service

        service.$students
            .receive(on: RunLoop.main)
            .assign(to: \.students, on: self)
            .store(in: &cancellables)

        service.requestStudentList()
    }

    func sendDisconnect(for student: String) {
        service?.sendDisconnect(for: student)
    }

    func startClass(at date: Date) {
        service?.startClass(at: date)
    }
}

