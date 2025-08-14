#if os(macOS)
import SwiftUI
import SwiftData

/// Detailed editor for a single lesson.
struct LessonDetailView: View {
    @Environment(\.modelContext) private var modelContext
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
            Button("Save") { try? modelContext.save() }
        }
    }
}
#Preview {
    let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: [Lesson.self], configurations: configuration)
    let context = container.mainContext
    let lesson = Lesson(title: "Preview Lesson", number: 1)
    context.insert(lesson)
    LessonDetailView(lesson: lesson)
        .modelContainer(container)
}
#endif
