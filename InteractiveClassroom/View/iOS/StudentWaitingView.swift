import SwiftUI

#if os(iOS) || os(macOS)
/// Displays a waiting screen for students along with current course and lesson information.
struct StudentWaitingView: View {
    @EnvironmentObject private var connectionManager: PeerConnectionManager

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                statusSection

                GroupBox("Current Course") {
                    if let course = connectionManager.currentCourse {
                        CourseInfoView(course: course)
                    } else {
                        Text("Course information unavailable")
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }

                GroupBox("Current Lesson") {
                    if let lesson = connectionManager.currentLesson {
                        LessonInfoView(lesson: lesson)
                    } else {
                        Text("Lesson information unavailable")
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Waiting")
    }

    /// Shows whether the class has started yet.
    private var statusSection: some View {
        Group {
            if connectionManager.classStarted {
                Text("Class has started.")
                    .font(.title2)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                Text("Waiting for the teacher to start the class…")
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
            }
        }
    }
}

/// Displays course information consistently across platforms.
private struct CourseInfoView: View {
    let course: Course

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(course.name)
                .font(.headline)
            Text(course.scheduledAt, format: .dateTime.year().month().day().hour().minute())
                .font(.subheadline)
                .foregroundStyle(.secondary)
            if !course.intro.isEmpty {
                Text(course.intro)
                    .font(.body)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// Displays lesson information consistently across platforms.
private struct LessonInfoView: View {
    let lesson: Lesson

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(lesson.title)
                .font(.headline)
            Text(lesson.scheduledAt, format: .dateTime.year().month().day().hour().minute())
                .font(.subheadline)
                .foregroundStyle(.secondary)
            if !lesson.intro.isEmpty {
                Text(lesson.intro)
                    .font(.body)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
#Preview {
    let manager = PeerConnectionManager()
    manager.currentCourse = Course(name: "Preview Course")
    manager.currentLesson = Lesson(title: "Preview Lesson", number: 1)
    NavigationStack { StudentWaitingView() }
        .environmentObject(manager)
}
#endif
