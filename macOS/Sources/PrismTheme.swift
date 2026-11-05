import SwiftUI
import AppKit

enum PrismTheme {
    static let accent = Color(nsColor: NSColor(name: nil) { appearance in
        if appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua {
            return NSColor(srgbRed: 100.0 / 255, green: 217.0 / 255, blue: 242.0 / 255, alpha: 1)
        }
        return NSColor(srgbRed: 8.0 / 255, green: 105.0 / 255, blue: 132.0 / 255, alpha: 1)
    })
}

struct PrismCard: ViewModifier {
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    func body(content: Content) -> some View {
        content
            .background {
                if reduceTransparency { RoundedRectangle(cornerRadius: 14).fill(Color(nsColor: .controlBackgroundColor)) }
                else { RoundedRectangle(cornerRadius: 14).fill(.thinMaterial) }
            }
            .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Color.primary.opacity(0.09), lineWidth: 0.5))
    }
}
extension View { func prismCard() -> some View { modifier(PrismCard()) } }
