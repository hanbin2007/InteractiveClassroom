#if os(macOS)
import SwiftUI
import SwiftData

/// Detailed editor for a single course.
struct CourseDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var course: Course

    var body: some View {
        Form {
            TextField("Name", text: $course.name)
                .onSubmit { try? modelContext.save() }
            TextEditor(text: $course.intro)
                .frame(minHeight: 100)
            DatePicker("Date", selection: $course.scheduledAt)
        }
        .padding()
        .frame(minWidth: 400, minHeight: 300)
        .toolbar {
            Button("Save") { try? modelContext.save() }
        }
    }
}
#Preview {
    let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: [Course.self], configurations: configuration)
    let context = container.mainContext
    let course = Course(name: "Preview Course")
    context.insert(course)
    return CourseDetailView(course: course)
        .modelContainer(container)
}
#endif
