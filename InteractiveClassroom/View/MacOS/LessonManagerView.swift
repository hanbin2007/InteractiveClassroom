#if os(macOS)
import SwiftUI
import SwiftData

/// Lists lessons for a specific course and allows CRUD operations.
struct LessonManagerView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var course: Course
    @State private var editingLesson: Lesson?

    var body: some View {
        VStack(alignment: .leading) {
            if course.lessons.isEmpty {
                Text("No lessons")
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                    .padding()
            } else {
                Table(course.lessons) {
                    TableColumn("No.") { lesson in
                        Text("\(lesson.number)")
                    }
                    TableColumn("Title") { lesson in
                        TextField("Lesson Title", text: Binding(
                            get: { lesson.title },
                            set: { lesson.title = $0 }
                        ))
                        .onSubmit { try? modelContext.save() }
                    }
                    TableColumn("Details") { lesson in
                        Button("Edit") {
                            editingLesson = lesson
                        }
                    }
                    TableColumn("") { lesson in
                        Button(role: .destructive) {
                            if let index = course.lessons.firstIndex(of: lesson) {
                                course.lessons.remove(at: index)
                                modelContext.delete(lesson)
                                for (idx, remain) in course.lessons.enumerated() {
                                    remain.number = idx + 1
                                }
                                try? modelContext.save()
                            }
                        } label: {
                            Text("Delete")
                        }
                    }
                }
                .frame(minHeight: 300)
            }
        }
        .padding()
        .frame(minWidth: 600, minHeight: 400)
        .navigationTitle("Lessons for \(course.name)")
        .toolbar {
            Button("Add") {
                let lesson = Lesson(title: "New Lesson", number: course.lessons.count + 1, course: course)
                course.lessons.append(lesson)
                try? modelContext.save()
            }
        }
        .sheet(item: $editingLesson) { lesson in
            NavigationStack {
                LessonDetailView(lesson: lesson)
                    .navigationTitle("Lesson Details")
            }
            .frame(minWidth: 400, minHeight: 300)
        }
    }
}
#Preview {
    NavigationStack {
        LessonManagerView(course: PreviewSampleData.sampleCourse)
    }
    .modelContainer(PreviewSampleData.container)
}
#endif
