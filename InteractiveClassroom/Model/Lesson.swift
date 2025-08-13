import Foundation
import SwiftData

/// Represents a single teaching session within a course.
@Model
final class Lesson {
    /// Title or topic of the lesson.
    var title: String
    /// Date when the lesson occurs.
    var date: Date
    /// Raw data for answer statistics collected in this lesson.
    var answerData: Data?
    /// Raw data for student information collected in this lesson.
    var studentData: Data?
    /// Associated course.
    @Relationship(inverse: \Course.lessons) var course: Course?

    init(title: String, date: Date = .now, course: Course? = nil, answerData: Data? = nil, studentData: Data? = nil) {
        self.title = title
        self.date = date
        self.course = course
        self.answerData = answerData
        self.studentData = studentData
    }
}
