import SwiftUI
import UIKit

/// Resolves to `dark` or `light` against the surrounding colour scheme, so the
/// Theme picker in Settings (Dark / Bright / Automatic) repaints the whole app.
private func adaptive(dark: UInt32, light: UInt32, darkAlpha: Double = 1, lightAlpha: Double = 1) -> Color {
    Color(UIColor { traits in
        let isLight = traits.userInterfaceStyle == .light
        return UIColor(hex: isLight ? light : dark, alpha: isLight ? lightAlpha : darkAlpha)
    })
}

private extension UIColor {
    convenience init(hex: UInt32, alpha: Double) {
        self.init(
            red: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: alpha
        )
    }
}

enum ColorTheme {
    // Smooth cosmic palette (dark) paired with a daylight palette (bright)
    static let background = adaptive(dark: 0x070B1F, light: 0xF2F5FB)
    static let backgroundDeep = adaptive(dark: 0x02030A, light: 0xE4EAF6)
    static let backgroundMid = adaptive(dark: 0x111433, light: 0xDCE4F2)
    static let surface = adaptive(dark: 0x181F45, light: 0xFFFFFF)
    static let surfaceElevated = adaptive(dark: 0x222A55, light: 0xF7F9FD)
    static let stroke = adaptive(dark: 0xFFFFFF, light: 0x1B2340, darkAlpha: 0.08, lightAlpha: 0.12)
    static let primaryAccent = adaptive(dark: 0xC9931F, light: 0xB07D0C)
    static let secondaryAccent = adaptive(dark: 0xFFD700, light: 0x9A6B00)
    static let textPrimary = adaptive(dark: 0xFFFFFF, light: 0x0B1020)
    static let textSecondary = adaptive(dark: 0xB8C5D6, light: 0x4A5568)
    static let success = adaptive(dark: 0x4ADE80, light: 0x15803D)
    static let warning = adaptive(dark: 0xFBBF24, light: 0xB45309)
    static let error = adaptive(dark: 0xEF4444, light: 0xDC2626)
}

// MARK: - Shared smooth background

struct AppBackground: View {
    var body: some View {
        LinearGradient(
            stops: [
                .init(color: adaptive(dark: 0x121A47, light: 0xE9EFFA), location: 0.0),
                .init(color: adaptive(dark: 0x0D0F33, light: 0xDCE5F5), location: 0.5),
                .init(color: adaptive(dark: 0x05081A, light: 0xCFDAEE), location: 1.0)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
}

// MARK: - Card style

struct GlassCardModifier: ViewModifier {
    var cornerRadius: CGFloat = 18
    var tint: Color = ColorTheme.secondaryAccent
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(ColorTheme.surface.opacity(0.55))
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [tint.opacity(0.35), ColorTheme.stroke],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }
}

extension View {
    func glassCard(cornerRadius: CGFloat = 18, tint: Color = ColorTheme.secondaryAccent) -> some View {
        modifier(GlassCardModifier(cornerRadius: cornerRadius, tint: tint))
    }

    /// Wraps a screen body with the shared cosmic background.
    func appScreenBackground() -> some View {
        ZStack {
            AppBackground()
            self
        }
    }

    func surfaceCard() -> some View {
        self.padding(16).glassCard()
    }
}

// MARK: - Reusable pill/chip

struct PillStyle: ViewModifier {
    var active: Bool
    func body(content: Content) -> some View {
        content
            .font(.caption.bold())
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Capsule().fill(active ? ColorTheme.primaryAccent : ColorTheme.surface.opacity(0.7))
            )
            .overlay(
                Capsule().strokeBorder(
                    active ? Color.clear : ColorTheme.stroke,
                    lineWidth: 1
                )
            )
            .foregroundStyle(active ? .black : ColorTheme.textPrimary)
    }
}

extension View {
    func pill(active: Bool) -> some View { modifier(PillStyle(active: active)) }
}

// MARK: - Section title (uppercase monospaced caption used across all screens)

struct SectionHeader: View {
    let text: String
    var icon: String? = nil
    var body: some View {
        HStack(spacing: 6) {
            if let icon { Image(systemName: icon).font(.system(size: 10, weight: .bold)) }
            Text(text)
        }
        .font(.system(size: 10, weight: .bold, design: .monospaced))
        .foregroundStyle(ColorTheme.textSecondary)
        .textCase(.uppercase)
    }
}

// MARK: - Theme-aware navigation chrome

extension View {
    /// Navigation-bar chrome that follows the Theme setting rather than being
    /// pinned to dark. `nil` (Automatic) lets the system decide.
    func themedToolbar() -> some View {
        toolbarColorScheme(SettingsManager.shared.theme.colorScheme, for: .navigationBar)
    }
}
