import Foundation

/// Represents the identity a user can choose when entering the app.
/// Screen is available on macOS while Teacher and Student are intended for iOS/iPadOS.
public enum UserRole: String, CaseIterable, Identifiable {
    case screen
    case teacher
    case student

    public var id: String { rawValue }
}
