#if os(macOS)
import SwiftUI
import SwiftData

/// Detailed editor for a single lesson.
struct LessonDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Bindable var lesson: Lesson

    var body: some View {
        Form {
            Text("Lesson #\(lesson.number)")
            TextField("Title", text: $lesson.title)
                .onSubmit { try? modelContext.save() }
            TextEditor(text: $lesson.intro)
                .frame(minHeight: 100)
            DatePicker("Date", selection: $lesson.scheduledAt)
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
    LessonDetailView(lesson: PreviewSampleData.sampleLessons.first!)
        .modelContainer(PreviewSampleData.container)
}
#endif
