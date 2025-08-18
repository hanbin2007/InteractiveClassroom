#if os(macOS)
import SwiftUI
import SwiftData
import AppKit

/// Initial window prompting user to select a course and lesson before starting service.
struct CourseSelectionView: View {
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Course.name, animation: .default) private var courses: [Course]
    @StateObject private var viewModel: OpenClassroomViewModel

    init(viewModel: @autoclosure @escaping () -> OpenClassroomViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel())
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                Picker("Course", selection: $viewModel.selectedCourse) {
                    Text("None").tag(Optional<Course>.none)
                    ForEach(courses) { course in
                        Text(course.name).tag(Optional(course))
                    }
                }
                .pickerStyle(.menu)
                Picker("Lesson", selection: $viewModel.selectedLesson) {
                    Text("None").tag(Optional<Lesson>.none)
                    ForEach(viewModel.lessons) { lesson in
                        Text(lesson.title).tag(Optional(lesson))
                    }
                }
                .pickerStyle(.menu)
                HStack {
                    Spacer()
                    Button("Open Classroom") {
                        viewModel.openClassroom()
                        dismiss()
                    }
                    .disabled(!viewModel.canOpen)
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
    let pairing = PairingService()
    let interaction = InteractionService(manager: pairing)
    let courseService = CourseSessionService(manager: pairing, interactionService: interaction)
    return CourseSelectionView(viewModel: OpenClassroomViewModel(courseSessionService: courseService, pairingService: pairing))
        .modelContainer(PreviewSampleData.container)
        .environmentObject(courseService)
        .environmentObject(pairing)
        .environmentObject(interaction)
}
#endif
