#if os(iOS) || os(macOS)
import SwiftUI

/// Shared constants governing overlay presentation behavior.
enum OverlayConstants {
    /// Initial scale applied when overlay content is inserted or removed.
    static let contentScale: CGFloat = 0.9
}
#endif
