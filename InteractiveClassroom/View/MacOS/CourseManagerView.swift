#if os(macOS)
import SwiftUI
import SwiftData

/// Lists all courses and allows CRUD operations.
struct CourseManagerView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Course.name, animation: .default) private var courses: [Course]

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text("Courses")
                    .font(.title2)
                Spacer()
                Button("Add") {
                    let course = Course(name: "New Course")
                    modelContext.insert(course)
                    try? modelContext.save()
                }
            }
            if courses.isEmpty {
                Text("No courses")
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                    .padding()
            } else {
                Table(courses) {
                    TableColumn("Name") { course in
                        Text(course.name)
                    }
                    TableColumn("Lessons") { course in
                        Button("Manage") {
                            LessonManagerWindowController.shared.show(for: course, container: modelContext.container)
                        }
                    }
                    TableColumn("") { course in
                        Button(role: .destructive) {
                            modelContext.delete(course)
                            try? modelContext.save()
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
