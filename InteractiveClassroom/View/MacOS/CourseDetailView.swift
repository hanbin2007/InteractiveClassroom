#if os(macOS)
import SwiftUI
import SwiftData

/// Detailed editor for a single course.
struct CourseDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
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
            Button("Save") {
                do {
                    try modelContext.save()
                    dismiss()
                } catch {
                    // Consider presenting the error to the user in a production app
                }
            }
        }
    }
}
#Preview {
    CourseDetailView(course: Course(name: "Preview Course"))
        .modelContainer(for: [Course.self], inMemory: true)
}
#endif
