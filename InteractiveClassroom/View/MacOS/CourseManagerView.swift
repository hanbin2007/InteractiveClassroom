#if os(macOS)
import SwiftUI
import SwiftData

/// Lists all courses and allows CRUD operations.
struct CourseManagerView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Course.name, animation: .default) private var courses: [Course]
    @State private var editingCourse: Course?

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading) {
                if courses.isEmpty {
                    Text("No courses")
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                        .padding()
                } else {
                    Table(courses) {
                        TableColumn("Name") { course in
                            TextField("Course Name", text: Binding(
                                get: { course.name },
                                set: { course.name = $0 }
                            ))
                            .onSubmit { try? modelContext.save() }
                        }
                        TableColumn("Lessons") { course in
                            NavigationLink("Manage") {
                                LessonManagerView(course: course)
                            }
                        }
                        TableColumn("Details") { course in
                            Button("Edit") {
                                editingCourse = course
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
            .navigationTitle("Courses")
            .toolbar {
                ToolbarItem {
                    Button {
                        let course = Course(name: "New Course")
                        modelContext.insert(course)
                        try? modelContext.save()
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Add Course")
                }
            }
            .sheet(item: $editingCourse) { course in
                NavigationStack {
                    CourseDetailView(course: course)
                        .navigationTitle("Course Details")
                }
                .frame(minWidth: 400, minHeight: 300)
            }
        }
    }
}
#Preview {
    CourseManagerView()
        .modelContainer(PreviewSampleData.container)
}
#endif
