import SwiftUI

enum BMOTheme {
    // MARK: - Colors
    static let backgroundPrimary = Color(red: 0.06, green: 0.07, blue: 0.10)
    static let backgroundSecondary = Color(red: 0.10, green: 0.11, blue: 0.15)
    static let backgroundCard = Color(red: 0.13, green: 0.14, blue: 0.19)
    static let backgroundCardHover = Color(red: 0.16, green: 0.17, blue: 0.22)

    static let accent = Color(red: 0.0, green: 0.90, blue: 0.98)
    static let accentDim = Color(red: 0.0, green: 0.55, blue: 0.62)
    static let accentGlow = Color(red: 0.0, green: 0.90, blue: 0.98).opacity(0.15)

    static let textPrimary = Color.white
    static let textSecondary = Color(white: 0.65)
    static let textTertiary = Color(white: 0.42)

    static let success = Color(red: 0.20, green: 0.85, blue: 0.45)
    static let warning = Color(red: 1.0, green: 0.75, blue: 0.20)
    static let error = Color(red: 1.0, green: 0.35, blue: 0.35)

    static let divider = Color.white.opacity(0.08)

    // MARK: - Radii
    static let radiusSmall: CGFloat = 8
    static let radiusMedium: CGFloat = 14
    static let radiusLarge: CGFloat = 20

    // MARK: - Spacing
    static let spacingXS: CGFloat = 4
    static let spacingSM: CGFloat = 8
    static let spacingMD: CGFloat = 16
    static let spacingLG: CGFloat = 24
    static let spacingXL: CGFloat = 32
}

// MARK: - Card modifier

struct CardStyle: ViewModifier {
    var padding: CGFloat = BMOTheme.spacingMD

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(BMOTheme.backgroundCard)
            .clipShape(RoundedRectangle(cornerRadius: BMOTheme.radiusMedium, style: .continuous))
    }
}

extension View {
    func bmoCard(padding: CGFloat = BMOTheme.spacingMD) -> some View {
        modifier(CardStyle(padding: padding))
    }
}

// MARK: - Status badge

struct StatusBadge: View {
    let label: String
    let color: Color

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(label)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(color)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(color.opacity(0.12))
        .clipShape(Capsule())
    }
}

// MARK: - Glow button style

struct BMOButtonStyle: ButtonStyle {
    var isPrimary: Bool = true

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .semibold))
            .foregroundColor(isPrimary ? BMOTheme.backgroundPrimary : BMOTheme.accent)
            .padding(.horizontal, 24)
            .padding(.vertical, 14)
            .background(
                isPrimary
                    ? AnyShapeStyle(BMOTheme.accent)
                    : AnyShapeStyle(BMOTheme.accent.opacity(0.12))
            )
            .clipShape(RoundedRectangle(cornerRadius: BMOTheme.radiusSmall, style: .continuous))
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}
