import SwiftUI

extension Color {
    // MARK: - Background Colors
    static let appBackground = Color(hex: "1a1a2e")
    static let cardBackground = Color(hex: "16213e")
    static let cardBackgroundHover = Color(hex: "1a2745")
    static let surfaceBackground = Color(hex: "0f3460")

    // MARK: - Accent Colors
    static let accentPurple = Color(hex: "6c5ce7")
    static let accentBlue = Color(hex: "0984e3")
    static let accentGradientStart = Color(hex: "6c5ce7")
    static let accentGradientEnd = Color(hex: "0984e3")

    // MARK: - Text Colors
    static let textPrimary = Color.white
    static let textSecondary = Color(hex: "a0a0b0")
    static let textTertiary = Color(hex: "6b6b80")

    // MARK: - Status Colors
    static let statusSuccess = Color(hex: "00b894")
    static let statusError = Color(hex: "e17055")
    static let statusWarning = Color(hex: "fdcb6e")

    // MARK: - Border Colors
    static let borderDefault = Color(hex: "2a2a4a")
    static let borderHighlight = Color(hex: "6c5ce7").opacity(0.5)

    // MARK: - Drop Zone
    static let dropZoneBorder = Color(hex: "6c5ce7").opacity(0.4)
    static let dropZoneBackground = Color(hex: "6c5ce7").opacity(0.05)
    static let dropZoneActiveBackground = Color(hex: "6c5ce7").opacity(0.15)
    static let dropZoneActiveBorder = Color(hex: "6c5ce7").opacity(0.8)

    // MARK: - Gradients
    static var accentGradient: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [accentGradientStart, accentGradientEnd]),
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    static var backgroundGradient: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [
                Color(hex: "1a1a2e"),
                Color(hex: "16213e")
            ]),
            startPoint: .top,
            endPoint: .bottom
        )
    }

    // MARK: - Hex Initializer
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - View Modifiers

struct GlassMorphismModifier: ViewModifier {
    var cornerRadius: CGFloat = 12

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .fill(Color.cardBackground.opacity(0.7))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(Color.borderDefault, lineWidth: 1)
                    )
            )
    }
}

extension View {
    func glassMorphism(cornerRadius: CGFloat = 12) -> some View {
        modifier(GlassMorphismModifier(cornerRadius: cornerRadius))
    }
}
