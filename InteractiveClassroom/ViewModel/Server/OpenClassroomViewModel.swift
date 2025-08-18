#if os(macOS)
import SwiftUI
import SwiftData

/// View model for the course selection ("Open Classroom") window.
@MainActor
final class OpenClassroomViewModel: ObservableObject {
    @Published var selectedCourse: Course?
    @Published var selectedLesson: Lesson?

    private let courseSessionService: CourseSessionService
    private let pairingService: PairingService

    init(courseSessionService: CourseSessionService, pairingService: PairingService) {
        self.courseSessionService = courseSessionService
        self.pairingService = pairingService
    }

    /// Lessons belonging to the selected course ordered by schedule.
    var lessons: [Lesson] {
        selectedCourse?.lessons.sorted { $0.scheduledAt < $1.scheduledAt } ?? []
    }

    /// Whether the "Open Classroom" action is currently available.
    var canOpen: Bool {
        selectedCourse != nil && selectedLesson != nil
    }

    /// Open the classroom using the selected course and lesson.
    func openClassroom() {
        guard let course = selectedCourse, let lesson = selectedLesson else { return }
        courseSessionService.selectCourse(course)
        courseSessionService.selectLesson(lesson)
        pairingService.openClassroom()
    }
}
#endif
