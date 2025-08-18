import Combine
import Foundation

@MainActor
final class StudentWaitingViewModel: ObservableObject {
    @Published var currentCourse: Course?
    @Published var currentLesson: Lesson?
    @Published var classStarted: Bool = false

    private var cancellables = Set<AnyCancellable>()
    private var isBound = false

    func bind(to connectionManager: PeerConnectionManager) {
        guard !isBound else { return }

        connectionManager.$currentCourse
            .receive(on: RunLoop.main)
            .assign(to: \.currentCourse, on: self)
            .store(in: &cancellables)

        connectionManager.$currentLesson
            .receive(on: RunLoop.main)
            .assign(to: \.currentLesson, on: self)
            .store(in: &cancellables)

        connectionManager.$classStarted
            .receive(on: RunLoop.main)
            .assign(to: \.classStarted, on: self)
            .store(in: &cancellables)

        isBound = true
    }
}

