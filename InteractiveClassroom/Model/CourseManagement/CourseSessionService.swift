import Foundation
import Combine

@MainActor
final class CourseSessionService: ObservableObject {
    @Published private(set) var currentCourse: Course?
    @Published private(set) var currentLesson: Lesson?
    @Published private(set) var students: [String] = []
    @Published private(set) var classStarted: Bool = false

    private let manager: PeerConnectionManager
    private var cancellables: Set<AnyCancellable> = []

    init(manager: PeerConnectionManager) {
        self.manager = manager

        manager.$currentCourse
            .receive(on: RunLoop.main)
            .sink { [weak self] in self?.currentCourse = $0 }
            .store(in: &cancellables)
        manager.$currentLesson
            .receive(on: RunLoop.main)
            .sink { [weak self] in self?.currentLesson = $0 }
            .store(in: &cancellables)
        manager.$students
            .receive(on: RunLoop.main)
            .sink { [weak self] in self?.students = $0 }
            .store(in: &cancellables)
        manager.$classStarted
            .receive(on: RunLoop.main)
            .sink { [weak self] in self?.classStarted = $0 }
            .store(in: &cancellables)
    }

    // MARK: - Course Session Controls

    func selectCourse(_ course: Course?) { manager.currentCourse = course }
    func selectLesson(_ lesson: Lesson?) { manager.currentLesson = lesson }
    func requestStudentList() { manager.requestStudentList() }
    func sendDisconnect(for name: String) { manager.sendDisconnectCommand(for: name) }
    func startClass(at date: Date) { manager.startClass(at: date) }
    func endClass() {
        manager.endClass()
        manager.currentCourse = nil
        manager.currentLesson = nil
    }
}
