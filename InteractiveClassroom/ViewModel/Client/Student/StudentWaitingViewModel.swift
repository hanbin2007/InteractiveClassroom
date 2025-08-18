import Combine
import Foundation

@MainActor
final class StudentWaitingViewModel: ObservableObject {
    @Published var currentCourse: Course?
    @Published var currentLesson: Lesson?
    @Published var classStarted: Bool = false

    private var cancellables = Set<AnyCancellable>()
    private var service: CourseSessionService?

    func bind(to service: CourseSessionService) {
        guard self.service == nil else { return }
        self.service = service

        service.$currentCourse
            .receive(on: RunLoop.main)
            .assign(to: \.currentCourse, on: self)
            .store(in: &cancellables)

        service.$currentLesson
            .receive(on: RunLoop.main)
            .assign(to: \.currentLesson, on: self)
            .store(in: &cancellables)

        service.$classStarted
            .receive(on: RunLoop.main)
            .assign(to: \.classStarted, on: self)
            .store(in: &cancellables)
    }
}

