import SwiftUI

enum PlatformTheme {
    static let background = Color(red: 0.06, green: 0.07, blue: 0.10)
    static let surface = Color(red: 0.11, green: 0.12, blue: 0.16)
    static let surfaceAlt = Color(red: 0.15, green: 0.16, blue: 0.21)
    static let accent = Color(red: 0.00, green: 0.84, blue: 0.96)
    static let success = Color(red: 0.20, green: 0.82, blue: 0.40)
    static let warning = Color(red: 0.98, green: 0.74, blue: 0.22)
    static let danger = Color(red: 1.00, green: 0.34, blue: 0.34)
    static let textPrimary = Color.white
    static let textSecondary = Color(white: 0.72)
    static let textTertiary = Color(white: 0.48)
    static let divider = Color.white.opacity(0.08)
}

struct PlatformCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(16)
            .background(PlatformTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

extension View {
    func platformCard() -> some View {
        modifier(PlatformCardModifier())
    }
}

struct PillBadge: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text)
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundColor(color)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(color.opacity(0.12))
            .clipShape(Capsule())
    }
}
