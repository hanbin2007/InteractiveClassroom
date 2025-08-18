#if os(macOS)
import SwiftUI
import SwiftData
import AppKit

/// Initial window prompting user to select a course and lesson before starting service.
struct CourseSelectionView: View {
    @EnvironmentObject private var courseSessionService: CourseSessionService
    @EnvironmentObject private var pairingService: PairingService
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Course.name, animation: .default) private var courses: [Course]
    @State private var selectedCourse: Course?
    @State private var selectedLesson: Lesson?

    var lessons: [Lesson] {
        selectedCourse?.lessons.sorted { $0.scheduledAt < $1.scheduledAt } ?? []
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
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
                    Button("Open Classroom") {
                        guard let course = selectedCourse, let lesson = selectedLesson else { return }
                        courseSessionService.selectCourse(course)
                        courseSessionService.selectLesson(lesson)
                        pairingService.openClassroom()
                        dismiss()
                    }
                    .disabled(selectedCourse == nil || selectedLesson == nil)
                }
            }
            .padding()
            .frame(minWidth: 350, minHeight: 200)
            .navigationTitle("Select Course and Lesson")
            .onAppear {
                NSApp.keyWindow?.identifier = NSUserInterfaceItemIdentifier("courseSelection")
            }
        }
    }
}
#Preview {
    let manager = PreviewSampleData.connectionManager
    let courseService = CourseSessionService(manager: manager)
    let pairing = PairingService(manager: manager)
    return CourseSelectionView()
        .environmentObject(courseService)
        .environmentObject(pairing)
        .modelContainer(PreviewSampleData.container)
}
#endif
