import Foundation
import SwiftData

/// Represents a single teaching session within a course.
@Model
final class Lesson {
    /// Title or topic of the lesson.
    var title: String
    /// Sequence number within the course.
    var number: Int
    /// Detailed description of the lesson.
    var intro: String
    /// Date and time when the lesson occurs.
    var scheduledAt: Date
    /// Raw data for answer statistics collected in this lesson.
    var answerData: Data?
    /// Raw data for student information collected in this lesson.
    var studentData: Data?
    /// Associated course.
    @Relationship var course: Course?

    init(title: String, number: Int, scheduledAt: Date = .now, intro: String = "", course: Course? = nil, answerData: Data? = nil, studentData: Data? = nil) {
        self.title = title
        self.number = number
        self.intro = intro
        self.scheduledAt = scheduledAt
        self.course = course
        self.answerData = answerData
        self.studentData = studentData
    }
}
