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
    /// Optional top-to-bottom tint gradient (overrides backgroundHex when 2+ stops).
    public var gradientHexes: [String]
    /// Strength (0...0.35) of the white specular sheen across the top of the zone.
    public var sheen: Double
    /// Draws the bright top-edge highlight used by the liquid glass look.
    public var glassHighlight: Bool
    public var category: String
    
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
        materialStyle: String = "thin",
        gradientHexes: [String] = [],
        sheen: Double = 0,
        glassHighlight: Bool = false,
        category: String = "Classic"
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
        self.gradientHexes = gradientHexes
        self.sheen = min(max(sheen, 0), 0.35)
        self.glassHighlight = glassHighlight
        self.category = category
    }

    /// The colours the tint is drawn with, top to bottom.
    public var tintStops: [String] { gradientHexes.count >= 2 ? gradientHexes : [backgroundHex] }
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
    
    // MARK: Liquid glass

    public static let liquidClear = ZoneTheme(
        id: "liquid_clear", name: "Liquid Clear", backgroundHex: "#FFFFFF", backgroundOpacity: 0.38,
        borderHex: "#FFFFFF8C", borderWidth: 1.0, cornerRadius: 22, titleColorHex: "#111114",
        accentColorHex: "#0060DF", materialStyle: "ultraThin",
        gradientHexes: ["#FFFFFF", "#EEF3FA"], sheen: 0.30, glassHighlight: true, category: "Liquid Glass")

    public static let liquidSmoke = ZoneTheme(
        id: "liquid_smoke", name: "Liquid Smoke", backgroundHex: "#16171C", backgroundOpacity: 0.42,
        borderHex: "#FFFFFF40", borderWidth: 1.0, cornerRadius: 22, titleColorHex: "#FFFFFF",
        accentColorHex: "#64D2FF", materialStyle: "ultraThin",
        gradientHexes: ["#2A2C34", "#0E0F13"], sheen: 0.16, glassHighlight: true, category: "Liquid Glass")

    public static let liquidAqua = ZoneTheme(
        id: "liquid_aqua", name: "Liquid Aqua", backgroundHex: "#0A5C8A", backgroundOpacity: 0.52,
        borderHex: "#A8E6FF80", borderWidth: 1.0, cornerRadius: 22, titleColorHex: "#FFFFFF",
        accentColorHex: "#7FE3FF", materialStyle: "ultraThin",
        gradientHexes: ["#11618F", "#06395C"], sheen: 0.12, glassHighlight: true, category: "Liquid Glass")

    public static let liquidRose = ZoneTheme(
        id: "liquid_rose", name: "Liquid Rose", backgroundHex: "#FFE3EC", backgroundOpacity: 0.48,
        borderHex: "#FFFFFF99", borderWidth: 1.0, cornerRadius: 22, titleColorHex: "#3A0A1C",
        accentColorHex: "#B0124F", materialStyle: "ultraThin",
        gradientHexes: ["#FFF0F5", "#FFD3E2"], sheen: 0.28, glassHighlight: true, category: "Liquid Glass")

    public static let liquidMint = ZoneTheme(
        id: "liquid_mint", name: "Liquid Mint", backgroundHex: "#DDF7EC", backgroundOpacity: 0.48,
        borderHex: "#FFFFFF99", borderWidth: 1.0, cornerRadius: 22, titleColorHex: "#062E1E",
        accentColorHex: "#0A7A4E", materialStyle: "ultraThin",
        gradientHexes: ["#EFFFF7", "#C9F0DE"], sheen: 0.28, glassHighlight: true, category: "Liquid Glass")

    public static let liquidAmethyst = ZoneTheme(
        id: "liquid_amethyst", name: "Liquid Amethyst", backgroundHex: "#3B1B6B", backgroundOpacity: 0.52,
        borderHex: "#D7B8FF70", borderWidth: 1.0, cornerRadius: 22, titleColorHex: "#FFFFFF",
        accentColorHex: "#D0A8FF", materialStyle: "ultraThin",
        gradientHexes: ["#5A2EA0", "#22104A"], sheen: 0.18, glassHighlight: true, category: "Liquid Glass")

    public static let liquidAmber = ZoneTheme(
        id: "liquid_amber", name: "Liquid Amber", backgroundHex: "#FFE7B8", backgroundOpacity: 0.5,
        borderHex: "#FFFFFF99", borderWidth: 1.0, cornerRadius: 22, titleColorHex: "#3A2100",
        accentColorHex: "#9A5200", materialStyle: "ultraThin",
        gradientHexes: ["#FFF4D9", "#FFD88A"], sheen: 0.26, glassHighlight: true, category: "Liquid Glass")

    // MARK: Gradients

    public static let oceanDepth = ZoneTheme(
        id: "ocean_depth", name: "Ocean Depth", isPro: true, backgroundHex: "#05304A", backgroundOpacity: 0.72,
        borderHex: "#4FD1FF55", borderWidth: 1.0, cornerRadius: 18, titleColorHex: "#E6F7FF",
        accentColorHex: "#4FD1FF", materialStyle: "thin",
        gradientHexes: ["#0B4F6C", "#021A2B"], sheen: 0.08, category: "Gradient")

    public static let sunsetBlend = ZoneTheme(
        id: "sunset_blend", name: "Sunset Blend", isPro: true, backgroundHex: "#7A1F3D", backgroundOpacity: 0.72,
        borderHex: "#FFB08A66", borderWidth: 1.0, cornerRadius: 18, titleColorHex: "#FFF1E8",
        accentColorHex: "#FFC08A", materialStyle: "thin",
        gradientHexes: ["#B4442F", "#5B1240"], sheen: 0.08, category: "Gradient")

    public static let northernLights = ZoneTheme(
        id: "northern_lights", name: "Northern Lights", isPro: true, backgroundHex: "#0C2B2A", backgroundOpacity: 0.74,
        borderHex: "#7CFFCB55", borderWidth: 1.0, cornerRadius: 18, titleColorHex: "#EFFFF8",
        accentColorHex: "#7CFFCB", materialStyle: "thin",
        gradientHexes: ["#0E5A4A", "#2A1452"], sheen: 0.08, category: "Gradient")

    public static let synthwave = ZoneTheme(
        id: "synthwave", name: "Synthwave", isPro: true, backgroundHex: "#2B0B45", backgroundOpacity: 0.8,
        borderHex: "#FF5FD288", borderWidth: 1.5, cornerRadius: 14, titleColorHex: "#FFE9FB",
        accentColorHex: "#FF8BE0", materialStyle: "thick",
        gradientHexes: ["#4A1270", "#14052A"], sheen: 0.06, category: "Gradient")

    // MARK: Solid & minimal

    public static let paperLight = ZoneTheme(
        id: "paper_light", name: "Paper", backgroundHex: "#FBF7EF", backgroundOpacity: 0.9,
        borderHex: "#00000022", borderWidth: 1.0, cornerRadius: 12, titleColorHex: "#2B2118",
        accentColorHex: "#8A5A00", materialStyle: "regular", category: "Solid")

    public static let graphite = ZoneTheme(
        id: "graphite", name: "Graphite", backgroundHex: "#2C2C2E", backgroundOpacity: 0.88,
        borderHex: "#FFFFFF1A", borderWidth: 1.0, cornerRadius: 12, titleColorHex: "#F2F2F7",
        accentColorHex: "#98989D", materialStyle: "regular", category: "Solid")

    public static let midnightGold = ZoneTheme(
        id: "midnight_gold", name: "Midnight Gold", isPro: true, backgroundHex: "#0B0B10", backgroundOpacity: 0.86,
        borderHex: "#E3B85466", borderWidth: 1.2, cornerRadius: 14, titleColorHex: "#F6D88A",
        accentColorHex: "#E3B854", materialStyle: "thick", category: "Solid")

    public static let highContrastDark = ZoneTheme(
        id: "high_contrast_dark", name: "High Contrast Dark", backgroundHex: "#000000", backgroundOpacity: 1.0,
        borderHex: "#FFFFFF", borderWidth: 2.0, cornerRadius: 10, titleColorHex: "#FFFFFF",
        accentColorHex: "#FFD60A", materialStyle: "thick", category: "Accessibility")

    public static let highContrastLight = ZoneTheme(
        id: "high_contrast_light", name: "High Contrast Light", backgroundHex: "#FFFFFF", backgroundOpacity: 1.0,
        borderHex: "#000000", borderWidth: 2.0, cornerRadius: 10, titleColorHex: "#000000",
        accentColorHex: "#0040DD", materialStyle: "thick", category: "Accessibility")

    public static let allThemes: [ZoneTheme] = [
        liquidClear, liquidSmoke, liquidAqua, liquidRose, liquidMint, liquidAmethyst, liquidAmber,
        glassBlur, darkFrost, lightFrost, slateTitanium, minimalWireframe,
        oceanDepth, sunsetBlend, northernLights, synthwave,
        auroraGlow, sunsetCoral, emeraldForest, cyberpunkNeon, roseGold, retroTerminal,
        paperLight, graphite, midnightGold, highContrastDark, highContrastLight
    ]

    public static let categoryOrder = ["Liquid Glass", "Classic", "Gradient", "Solid", "Accessibility"]
    
    public static func theme(for id: String) -> ZoneTheme {
        allThemes.first(where: { $0.id == id }) ?? glassBlur
    }
}

