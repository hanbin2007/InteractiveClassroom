import Foundation
import SwiftData

/// Represents a teaching course which groups multiple lessons and clients.
@Model
final class Course {
    /// Name of the course.
    var name: String
    /// Lessons under this course.
    @Relationship(deleteRule: .cascade) var lessons: [Lesson] = []
    /// Clients that joined this course.
    @Relationship(deleteRule: .cascade) var clients: [ClientInfo] = []

    init(name: String) {
        self.name = name
    }
}
