import Foundation
import SwiftUI

public struct ZoneTheme: Identifiable, Codable, Equatable {
    public var id: String
    public var name: String
    public var isPro: Bool
    public var backgroundHex: String
    public var backgroundOpacity: Double
    public var borderHex: String
    public var borderWidth: Double
    public var cornerRadius: Double
    public var titleColorHex: String
    public var accentColorHex: String
    public var materialStyle: String // "ultraThin", "thin", "regular", "thick"
    
    public init(
        id: String,
        name: String,
        isPro: Bool = false,
        backgroundHex: String = "#1E1E24",
        backgroundOpacity: Double = 0.65,
        borderHex: String = "#FFFFFF22",
        borderWidth: Double = 1.0,
        cornerRadius: Double = 16.0,
        titleColorHex: String = "#FFFFFF",
        accentColorHex: String = "#0A84FF",
        materialStyle: String = "thin"
    ) {
        self.id = id
        self.name = name
        self.isPro = isPro
        self.backgroundHex = backgroundHex
        self.backgroundOpacity = backgroundOpacity
        self.borderHex = borderHex
        self.borderWidth = borderWidth
        self.cornerRadius = cornerRadius
        self.titleColorHex = titleColorHex
        self.accentColorHex = accentColorHex
        self.materialStyle = materialStyle
    }
}

public struct ThemePresets {
    public static let glassBlur = ZoneTheme(
        id: "glass_blur",
        name: "Liquid Glass",
        isPro: false,
        backgroundHex: "#121217",
        backgroundOpacity: 0.45,
        borderHex: "#FFFFFF33",
        borderWidth: 1.0,
        cornerRadius: 16.0,
        titleColorHex: "#FFFFFF",
        accentColorHex: "#0A84FF",
        materialStyle: "ultraThin"
    )
    
    public static let darkFrost = ZoneTheme(
        id: "dark_frost",
        name: "Dark Frost",
        isPro: false,
        backgroundHex: "#0D0E12",
        backgroundOpacity: 0.75,
        borderHex: "#FFFFFF1F",
        borderWidth: 1.0,
        cornerRadius: 14.0,
        titleColorHex: "#F2F2F7",
        accentColorHex: "#5E5CE6",
        materialStyle: "regular"
    )
    
    public static let lightFrost = ZoneTheme(
        id: "light_frost",
        name: "Light Frost",
        isPro: false,
        backgroundHex: "#F7F8FA",
        backgroundOpacity: 0.65,
        borderHex: "#00000018",
        borderWidth: 1.0,
        cornerRadius: 14.0,
        titleColorHex: "#1C1C1E",
        accentColorHex: "#007AFF",
        materialStyle: "regular"
    )
    
    public static let auroraGlow = ZoneTheme(
        id: "aurora_glow",
        name: "Aurora Glow",
        isPro: true,
        backgroundHex: "#160C28",
        backgroundOpacity: 0.68,
        borderHex: "#AF52DE66",
        borderWidth: 1.5,
        cornerRadius: 18.0,
        titleColorHex: "#F4EBFF",
        accentColorHex: "#BF5AF2",
        materialStyle: "thin"
    )
    
    public static let sunsetCoral = ZoneTheme(
        id: "sunset_coral",
        name: "Sunset Coral",
        isPro: true,
        backgroundHex: "#26110D",
        backgroundOpacity: 0.65,
        borderHex: "#FF624755",
        borderWidth: 1.5,
        cornerRadius: 16.0,
        titleColorHex: "#FFE4DF",
        accentColorHex: "#FF6434",
        materialStyle: "thin"
    )
    
    public static let emeraldForest = ZoneTheme(
        id: "emerald_forest",
        name: "Emerald Forest",
        isPro: true,
        backgroundHex: "#0B1D15",
        backgroundOpacity: 0.70,
        borderHex: "#30D15855",
        borderWidth: 1.5,
        cornerRadius: 16.0,
        titleColorHex: "#E6FBF0",
        accentColorHex: "#30D158",
        materialStyle: "thin"
    )
    
    public static let cyberpunkNeon = ZoneTheme(
        id: "cyberpunk_neon",
        name: "Cyberpunk",
        isPro: true,
        backgroundHex: "#0A0914",
        backgroundOpacity: 0.85,
        borderHex: "#00F5FF88",
        borderWidth: 2.0,
        cornerRadius: 12.0,
        titleColorHex: "#00F5FF",
        accentColorHex: "#FF007F",
        materialStyle: "thick"
    )
    
    public static let roseGold = ZoneTheme(
        id: "rose_gold",
        name: "Rose Quartz",
        isPro: true,
        backgroundHex: "#24151B",
        backgroundOpacity: 0.65,
        borderHex: "#FF9FBA55",
        borderWidth: 1.5,
        cornerRadius: 16.0,
        titleColorHex: "#FFF0F4",
        accentColorHex: "#FF699E",
        materialStyle: "thin"
    )
    
    public static let slateTitanium = ZoneTheme(
        id: "slate_titanium",
        name: "Slate Titanium",
        isPro: false,
        backgroundHex: "#1E222A",
        backgroundOpacity: 0.75,
        borderHex: "#737D8C44",
        borderWidth: 1.0,
        cornerRadius: 14.0,
        titleColorHex: "#E5E9F0",
        accentColorHex: "#88C0D0",
        materialStyle: "regular"
    )
    
    public static let retroTerminal = ZoneTheme(
        id: "retro_terminal",
        name: "Matrix Terminal",
        isPro: true,
        backgroundHex: "#051105",
        backgroundOpacity: 0.90,
        borderHex: "#33FF3377",
        borderWidth: 1.5,
        cornerRadius: 6.0,
        titleColorHex: "#33FF33",
        accentColorHex: "#00FF66",
        materialStyle: "thick"
    )
    
    public static let minimalWireframe = ZoneTheme(
        id: "minimal_wireframe",
        name: "Minimal Line",
        isPro: false,
        backgroundHex: "#000000",
        backgroundOpacity: 0.20,
        borderHex: "#FFFFFF40",
        borderWidth: 1.0,
        cornerRadius: 12.0,
        titleColorHex: "#FFFFFF",
        accentColorHex: "#FFFFFF",
        materialStyle: "ultraThin"
    )
    
    public static let allThemes: [ZoneTheme] = [
        glassBlur,
        darkFrost,
        lightFrost,
        slateTitanium,
        minimalWireframe,
        auroraGlow,
        sunsetCoral,
        emeraldForest,
        cyberpunkNeon,
        roseGold,
        retroTerminal
    ]
    
    public static func theme(for id: String) -> ZoneTheme {
        allThemes.first(where: { $0.id == id }) ?? glassBlur
    }
}

// SwiftUI Color extension for Hex decoding
extension Color {
    public init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB or RGBA (32-bit: RRGGBBAA)
            (r, g, b, a) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
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
