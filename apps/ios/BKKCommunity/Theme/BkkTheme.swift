import SwiftUI

public extension Color {
    init(hex: String) {
        let hexCleaned = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hexCleaned).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hexCleaned.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
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

    // Android BKK Theme Color Tokens
    static let bkkNavy = Color(hex: "#1F4E79")
    static let bkkDeepNavy = Color(hex: "#123A5C")
    static let bkkBlue = Color(hex: "#2E75B6")
    static let bkkLightBlue = Color(hex: "#D6E4F0")
    static let bkkSky = Color(hex: "#EAF3FA")
    static let bkkGold = Color(hex: "#BF7600")
    static let bkkGoldSurface = Color(hex: "#FFF0C9")
    static let bkkGreen = Color(hex: "#315C24")
    static let bkkGreenSurface = Color(hex: "#E1EFDC")
    static let bkkTeal = Color(hex: "#00747A")
    static let bkkTealSurface = Color(hex: "#DDF1F2")
    static let bkkRed = Color(hex: "#B00020")
    static let bkkRedSurface = Color(hex: "#FCE1E5")
    static let bkkInk = Color(hex: "#1B1B25")
    static let bkkMuted = Color(hex: "#586674")
    static let bkkLine = Color(hex: "#D7E1E8")
    static let bkkSurface = Color(hex: "#F5F8FA")
    static let bkkWarmSurface = Color(hex: "#FFFBF5")
}

public struct BkkTheme {
    public static let topBarGradient = LinearGradient(
        colors: [.bkkDeepNavy, .bkkNavy, .bkkBlue],
        startPoint: .leading,
        endPoint: .trailing
    )
}
