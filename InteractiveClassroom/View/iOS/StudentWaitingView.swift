import SwiftUI

#if os(iOS)
/// Displays a waiting screen for students along with current course and lesson information.
struct StudentWaitingView: View {
    @EnvironmentObject private var connectionManager: PeerConnectionManager

    var body: some View {
        List {
            Section {
                if connectionManager.classStarted {
                    Text("Class has started.")
                        .font(.title2)
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    Text("Waiting for the teacher to start the class...")
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            }

            if let course = connectionManager.currentCourse {
                Section("Current Course") {
                    Text(course.name)
                        .font(.headline)
                    Text(course.scheduledAt, format: .dateTime.year().month().day().hour().minute())
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    if !course.intro.isEmpty {
                        Text(course.intro)
                    }
                }
            }

            if let lesson = connectionManager.currentLesson {
                Section("Current Lesson") {
                    Text(lesson.title)
                        .font(.headline)
                    Text(lesson.scheduledAt, format: .dateTime.year().month().day().hour().minute())
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    if !lesson.intro.isEmpty {
                        Text(lesson.intro)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Waiting")
    }
}
#endif
