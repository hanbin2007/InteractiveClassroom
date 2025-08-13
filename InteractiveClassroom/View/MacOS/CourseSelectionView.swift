#if os(macOS)
import SwiftUI
import SwiftData

/// Initial window prompting user to select a course and lesson before starting service.
struct CourseSelectionView: View {
    @EnvironmentObject private var connectionManager: PeerConnectionManager
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Course.name, animation: .default) private var courses: [Course]
    @State private var selectedCourse: Course?
    @State private var selectedLesson: Lesson?

    var lessons: [Lesson] {
        selectedCourse?.lessons.sorted { $0.scheduledAt < $1.scheduledAt } ?? []
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Select Course and Lesson")
                .font(.title3)
            Picker("Course", selection: $selectedCourse) {
                Text("None").tag(Optional<Course>.none)
                ForEach(courses) { course in
                    Text(course.name).tag(Optional(course))
                }
            }
            .pickerStyle(.menu)
            Picker("Lesson", selection: $selectedLesson) {
                Text("None").tag(Optional<Lesson>.none)
                ForEach(lessons) { lesson in
                    Text(lesson.title).tag(Optional(lesson))
                }
            }
            .pickerStyle(.menu)
            HStack {
                Spacer()
                Button("Start") {
                    guard let course = selectedCourse, let lesson = selectedLesson else { return }
                    connectionManager.currentCourse = course
                    connectionManager.currentLesson = lesson
                    connectionManager.startHosting()
                    CourseSelectionWindowController.shared.close()
                }
                .disabled(selectedCourse == nil || selectedLesson == nil)
            }
        }
        .padding()
        .frame(minWidth: 350, minHeight: 200)
    }
}
#endif
