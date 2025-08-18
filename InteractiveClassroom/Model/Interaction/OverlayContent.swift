import SwiftUI

/// Corner positions for floating overlay content.
enum OverlayCorner {
    case topLeft, topRight, bottomLeft, bottomRight
}

/// Supported templates for overlay content.
enum OverlayTemplate {
    /// Full-screen content with a blurred color background.
    case fullScreen(color: Color)
    /// Floating content anchored to one corner without any background.
    case floatingCorner(position: OverlayCorner)
}

/// A type-erased container for overlay content views.
struct OverlayContent {
    let template: OverlayTemplate
    let view: AnyView

    init<Content: View>(template: OverlayTemplate, @ViewBuilder content: () -> Content) {
        self.template = template
        self.view = AnyView(content())
    }
}
