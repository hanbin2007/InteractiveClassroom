#if DEBUG
import SwiftUI
import SwiftData

/// Provides an in-memory model container populated with sample data for previews.
@MainActor
enum PreviewSampleData {
    static var sampleCourse: Course = Course(name: "Preview Course", intro: "Example course")
    static var sampleLessons: [Lesson] = [
        Lesson(title: "Lesson 1", number: 1, course: sampleCourse),
        Lesson(title: "Lesson 2", number: 2, course: sampleCourse)
    ]
    static var sampleClients: [ClientInfo] = [
        ClientInfo(deviceName: "iPad", nickname: "Alice", role: "Student", isConnected: true, course: sampleCourse),
        ClientInfo(deviceName: "MacBook", nickname: "Bob", role: "Student", isConnected: false, course: sampleCourse)
    ]

    /// In-memory container seeded with preview data.
    static let container: ModelContainer = {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: Course.self, Lesson.self, ClientInfo.self, configurations: config)
        let context = container.mainContext
        sampleCourse.lessons = sampleLessons
        sampleCourse.clients = sampleClients
        context.insert(sampleCourse)
        sampleLessons.forEach { context.insert($0) }
        sampleClients.forEach { context.insert($0) }
        try? context.save()
        return container
    }()

    /// Connection manager configured with the preview container.
    static let connectionManager: PeerConnectionManager = {
        let manager = PairingService(modelContext: container.mainContext, currentCourse: sampleCourse, currentLesson: sampleLessons.first)
        manager.teacherCode = "123456"
        manager.studentCode = "654321"
        return manager
    }()
}
#endif
