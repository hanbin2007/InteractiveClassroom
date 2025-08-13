#if os(macOS)
import SwiftUI
import SwiftData

/// Lists lessons for a specific course and allows CRUD operations.
struct LessonManagerView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var course: Course

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text("Lessons for \(course.name)")
                    .font(.title2)
                Spacer()
                Button("Add") {
                    let lesson = Lesson(title: "New Lesson", course: course)
                    course.lessons.append(lesson)
                    try? modelContext.save()
                }
            }
            if course.lessons.isEmpty {
                Text("No lessons")
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                    .padding()
            } else {
                Table(course.lessons) {
                    TableColumn("Title") { lesson in
                        Text(lesson.title)
                    }
                    TableColumn("Date") { lesson in
                        Text(lesson.date, format: Date.FormatStyle(date: .numeric, time: .shortened))
                    }
                    TableColumn("") { lesson in
                        Button(role: .destructive) {
                            if let index = course.lessons.firstIndex(of: lesson) {
                                course.lessons.remove(at: index)
                                modelContext.delete(lesson)
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
    }
}
#endif
