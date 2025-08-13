import Foundation
import SwiftData

/// Represents a teaching course which groups multiple lessons and clients.
@Model
final class Course {
    /// Name of the course.
    var name: String
    /// Short introduction or description for the course.
    var intro: String
    /// Scheduled date and time for the course.
    var scheduledAt: Date
    /// Lessons under this course.
    @Relationship(deleteRule: .cascade) var lessons: [Lesson] = []
    /// Clients that joined this course.
    @Relationship(deleteRule: .cascade) var clients: [ClientInfo] = []

    init(name: String, intro: String = "", scheduledAt: Date = .now) {
        self.name = name
        self.intro = intro
        self.scheduledAt = scheduledAt
    }
}
