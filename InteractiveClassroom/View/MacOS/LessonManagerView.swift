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
                    let lesson = Lesson(title: "New Lesson", number: course.lessons.count + 1, course: course)
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
                            LessonDetailWindowController.shared.show(lesson: lesson, container: modelContext.container)
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
    }
}
#Preview {
    let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: [Course.self, Lesson.self], configurations: configuration)
    let context = container.mainContext
    let course = Course(name: "Preview Course")
    course.lessons.append(Lesson(title: "Lesson 1", number: 1, course: course))
    context.insert(course)
    return LessonManagerView(course: course)
        .modelContainer(container)
}
#endif
