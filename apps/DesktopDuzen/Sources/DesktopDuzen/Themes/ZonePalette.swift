import SwiftUI
import AppKit

// MARK: - Colour maths (WCAG 2.x)

public struct RGBAColor: Equatable {
    public var r: Double
    public var g: Double
    public var b: Double
    public var a: Double

    public init(r: Double, g: Double, b: Double, a: Double = 1) {
        self.r = r; self.g = g; self.b = b; self.a = a
    }

    /// Parses #RGB, #RRGGBB and #RRGGBBAA. Invalid input returns opaque black.
    public init(hex: String) {
        let cleaned = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var value: UInt64 = 0
        guard Scanner(string: cleaned).scanHexInt64(&value) else {
            self.init(r: 0, g: 0, b: 0, a: 1)
            return
        }
        switch cleaned.count {
        case 3:
            self.init(r: Double((value >> 8) & 0xF) * 17 / 255, g: Double((value >> 4) & 0xF) * 17 / 255,
                      b: Double(value & 0xF) * 17 / 255, a: 1)
        case 6:
            self.init(r: Double((value >> 16) & 0xFF) / 255, g: Double((value >> 8) & 0xFF) / 255,
                      b: Double(value & 0xFF) / 255, a: 1)
        case 8:
            self.init(r: Double((value >> 24) & 0xFF) / 255, g: Double((value >> 16) & 0xFF) / 255,
                      b: Double((value >> 8) & 0xFF) / 255, a: Double(value & 0xFF) / 255)
        default:
            self.init(r: 0, g: 0, b: 0, a: 1)
        }
    }

    public static let white = RGBAColor(r: 1, g: 1, b: 1)
    public static let black = RGBAColor(r: 0, g: 0, b: 0)

    public var hexString: String {
        func c(_ v: Double) -> Int { Int((min(max(v, 0), 1) * 255).rounded()) }
        return String(format: "#%02X%02X%02X", c(r), c(g), c(b))
    }

    /// Source-over compositing of `self` (at `alpha`) on an opaque backdrop.
    public func over(_ backdrop: RGBAColor, alpha: Double) -> RGBAColor {
        let k = min(max(alpha, 0), 1)
        return RGBAColor(r: r * k + backdrop.r * (1 - k),
                         g: g * k + backdrop.g * (1 - k),
                         b: b * k + backdrop.b * (1 - k))
    }

    public var relativeLuminance: Double {
        func channel(_ c: Double) -> Double { c <= 0.03928 ? c / 12.92 : pow((c + 0.055) / 1.055, 2.4) }
        return 0.2126 * channel(r) + 0.7152 * channel(g) + 0.0722 * channel(b)
    }

    public static func contrastRatio(_ a: RGBAColor, _ b: RGBAColor) -> Double {
        let la = a.relativeLuminance, lb = b.relativeLuminance
        return (max(la, lb) + 0.05) / (min(la, lb) + 0.05)
    }

    public var color: Color { Color(.sRGB, red: r, green: g, blue: b, opacity: a) }
    public var nsColor: NSColor { NSColor(srgbRed: r, green: g, blue: b, alpha: a) }
}

extension Color {
    public init(hex: String) {
        self = RGBAColor(hex: hex).color
    }
}

// MARK: - Palette

/// Every colour a zone draws with, derived from its effective background so text stays legible
/// whatever the theme, custom tint, transparency or system appearance.
public struct ZonePalette: Equatable {
    public static let minimumTextContrast = 4.5  // WCAG AA, normal text
    public static let minimumIconContrast = 3.0  // WCAG AA, graphics / large text

    public var isDark: Bool
    public var tint: RGBAColor
    /// Opacity actually used to draw the tint (may be raised above the requested value for legibility).
    public var tintOpacity: Double
    /// Worst-case colour behind the text, used for all contrast decisions.
    public var effectiveBackground: RGBAColor
    /// Every composited background the text can sit on (gradient stops and the sheen).
    public var backgrounds: [RGBAColor]
    public var primaryRGB: RGBAColor
    public var titleRGB: RGBAColor
    public var accentRGB: RGBAColor
    public var secondaryOpacity: Double
    public var borderRGB: RGBAColor
    public var materialStyle: String
    /// Tint colours top to bottom (one for flat themes).
    public var stops: [RGBAColor]
    public var sheen: Double
    public var glassHighlight: Bool
    public var cornerRadius: Double
    public var borderWidth: Double
    /// Fully or mostly transparent zone: no material, labels drawn with a readability halo.
    public var isClear: Bool = false
    public var showBorder: Bool = true

    // Approximate colours of the blur material in each appearance, with 25 % of a worst-case
    // wallpaper (white for dark material, black for light material) bleeding through.
    public static let darkMaterialBase = RGBAColor(hex: "#232327").over(.white, alpha: 0.75)
    public static let lightMaterialBase = RGBAColor(hex: "#ECECEE").over(.black, alpha: 0.75)

    public static func make(theme: ZoneTheme, customHex: String? = nil, customOpacity: Double? = nil, depth: Int = 0) -> ZonePalette {
        // A custom colour replaces the whole theme tint (gradient and sheen included).
        let stops: [RGBAColor] = customHex.map { [RGBAColor(hex: $0)] } ?? theme.tintStops.map { RGBAColor(hex: $0) }
        let tint = stops[stops.count / 2]
        let sheen = customHex == nil ? theme.sheen : 0
        let requested = min(max(customOpacity ?? theme.backgroundOpacity, 0.0), 1.0)

        // Evaluate both appearances on every *composited* gradient stop (plus the sheen-brightened
        // top, where the title sits) and keep the more legible result. Text must pass on the
        // worst stop. Pure black or white always reaches >= 4.58:1 on any single opaque colour.
        struct Candidate { var isDark: Bool; var opacity: Double; var effective: RGBAColor; var primary: RGBAColor; var contrast: Double }
        func composites(base: RGBAColor, opacity: Double) -> [RGBAColor] {
            var result = stops.map { $0.over(base, alpha: opacity) }
            if sheen > 0, let top = result.first { result.append(RGBAColor.white.over(top, alpha: sheen)) }
            return result
        }
        func evaluate(dark: Bool) -> Candidate {
            let base = dark ? darkMaterialBase : lightMaterialBase
            func pick(_ bgs: [RGBAColor]) -> (RGBAColor, Double, RGBAColor) {
                let worstWhite = bgs.min { RGBAColor.contrastRatio(.white, $0) < RGBAColor.contrastRatio(.white, $1) }!
                let worstBlack = bgs.min { RGBAColor.contrastRatio(.black, $0) < RGBAColor.contrastRatio(.black, $1) }!
                let w = RGBAColor.contrastRatio(.white, worstWhite), b = RGBAColor.contrastRatio(.black, worstBlack)
                return w >= b ? (.white, w, worstWhite) : (.black, b, worstBlack)
            }
            var opacity = requested
            var (primary, contrast, worst) = pick(composites(base: base, opacity: opacity))
            while contrast < minimumTextContrast + 0.5 && opacity < 1.0 {
                opacity = min(1.0, opacity + 0.05)
                (primary, contrast, worst) = pick(composites(base: base, opacity: opacity))
            }
            return Candidate(isDark: dark, opacity: opacity, effective: worst, primary: primary, contrast: contrast)
        }
        let tintPrefersDark = RGBAColor.contrastRatio(.white, tint) >= RGBAColor.contrastRatio(.black, tint)
        let preferred = evaluate(dark: tintPrefersDark)
        let alternative = evaluate(dark: !tintPrefersDark)
        // Prefer the tint-matched material; switch only if it cannot reach the target.
        let chosen = (preferred.contrast >= minimumTextContrast || preferred.contrast >= alternative.contrast) ? preferred : alternative
        // Safety net for gradients/sheen that no text colour can clear even at full opacity:
        // pull every stop toward black (or white) and soften the sheen, then re-evaluate.
        if chosen.contrast < minimumTextContrast && customHex == nil && depth < 10 {
            var adjusted = theme
            let toward: RGBAColor = chosen.primary == .white ? .black : .white
            adjusted.gradientHexes = theme.tintStops.count >= 2
                ? theme.tintStops.map { RGBAColor(hex: $0).over(toward, alpha: 0.85).hexString } : []
            adjusted.backgroundHex = RGBAColor(hex: theme.backgroundHex).over(toward, alpha: 0.85).hexString
            adjusted.sheen = theme.sheen * 0.6
            return make(theme: adjusted, customHex: nil, customOpacity: customOpacity, depth: depth + 1)
        }
        let isDark = chosen.isDark
        let primary = chosen.primary
        let opacity = chosen.opacity
        let effective = chosen.effective

        let backgrounds = composites(base: isDark ? darkMaterialBase : lightMaterialBase, opacity: opacity)
        func worstContrast(_ c: RGBAColor) -> Double { backgrounds.map { RGBAColor.contrastRatio(c, $0) }.min() ?? 1 }

        let themeTitle = RGBAColor(hex: theme.titleColorHex)
        let title = (customHex == nil && worstContrast(themeTitle) >= minimumTextContrast) ? themeTitle : primary
        let themeAccent = RGBAColor(hex: theme.accentColorHex)
        let accent = worstContrast(themeAccent) >= minimumIconContrast ? themeAccent : primary

        // Most subdued secondary opacity that still meets AA on every stop (falls back to full strength).
        var secondary = 1.0
        for candidate in [0.72, 0.8, 0.88] {
            let ok = backgrounds.allSatisfy { RGBAColor.contrastRatio(primary.over($0, alpha: candidate), $0) >= minimumTextContrast }
            if ok { secondary = candidate; break }
        }

        let border: RGBAColor
        if customHex == nil {
            border = RGBAColor(hex: theme.borderHex)
        } else {
            border = RGBAColor(r: primary.r, g: primary.g, b: primary.b, a: 0.18)
        }

        return ZonePalette(isDark: isDark, tint: tint, tintOpacity: opacity, effectiveBackground: effective, backgrounds: backgrounds,
                           primaryRGB: primary, titleRGB: title, accentRGB: accent, secondaryOpacity: secondary,
                           borderRGB: border, materialStyle: theme.materialStyle,
                           stops: stops, sheen: sheen, glassHighlight: customHex == nil && theme.glassHighlight,
                           cornerRadius: theme.cornerRadius, borderWidth: theme.borderWidth)
    }

    public static func forWidget(_ widget: DesktopWidget) -> ZonePalette {
        let theme = ThemePresets.theme(for: widget.themeID)
        var p: ZonePalette
        if let opacity = widget.backgroundOpacity, opacity < ZoneModel.clearModeThreshold {
            p = clear(theme: theme, customHex: nil, opacity: opacity)
        } else {
            p = make(theme: theme, customOpacity: widget.backgroundOpacity)
        }
        p.showBorder = widget.showBorder
        return p
    }

    public static func forZone(_ zone: ZoneModel) -> ZonePalette {
        let theme = ThemePresets.theme(for: zone.themeID)
        var p: ZonePalette
        if let opacity = zone.customBackgroundOpacity, opacity < ZoneModel.clearModeThreshold {
            p = clear(theme: theme, customHex: zone.customBackgroundHex, opacity: opacity)
        } else {
            p = make(theme: theme, customHex: zone.customBackgroundHex, customOpacity: zone.customBackgroundOpacity)
        }
        p.showBorder = zone.showBorder
        return p
    }

    /// Clear mode: the zone background is (nearly) invisible, so contrast cannot come from the
    /// fill. Text is white with a dark halo (the convention Finder uses for desktop icon labels),
    /// which stays readable on light and dark wallpapers alike.
    public static func clear(theme: ZoneTheme, customHex: String?, opacity: Double) -> ZonePalette {
        let stops: [RGBAColor] = customHex.map { [RGBAColor(hex: $0)] } ?? theme.tintStops.map { RGBAColor(hex: $0) }
        var p = make(theme: theme, customHex: customHex, customOpacity: 1.0)
        p.isClear = true
        p.stops = stops
        p.tint = stops[stops.count / 2]
        p.tintOpacity = max(0, opacity)
        p.sheen = 0
        p.glassHighlight = false
        p.isDark = true
        p.primaryRGB = .white
        p.titleRGB = .white
        p.accentRGB = .white
        p.secondaryOpacity = 0.92
        p.borderRGB = RGBAColor(r: 1, g: 1, b: 1, a: opacity <= 0.01 ? 0 : 0.35)
        return p
    }

    public static let fallback = ZonePalette.make(theme: ThemePresets.glassBlur)

    // SwiftUI conveniences
    public var primary: Color { primaryRGB.color }
    public var secondary: Color { primaryRGB.color.opacity(secondaryOpacity) }
    public var title: Color { titleRGB.color }
    public var accent: Color { accentRGB.color }
    public var tintColor: Color { tint.color.opacity(tintOpacity) }
    public var tintGradient: LinearGradient {
        LinearGradient(colors: stops.map { $0.color.opacity(tintOpacity) }, startPoint: .top, endPoint: .bottom)
    }
    public var border: Color { borderRGB.color }
    public var controlFill: Color { isClear ? Color.black.opacity(0.28) : primaryRGB.color.opacity(0.10) }
    public var controlFillStrong: Color { primaryRGB.color.opacity(0.18) }
    public var selectionFill: Color { accentRGB.color.opacity(0.28) }
    /// Appearance of the blur material; the contrast maths assumed this material.
    public var appearance: NSAppearance? { NSAppearance(named: isDark ? .darkAqua : .aqua) }
    /// Follows the text colour, so system controls drawn inside the zone match it.
    public var colorScheme: ColorScheme { primaryRGB == .white ? .dark : .light }

    public var material: NSVisualEffectView.Material {
        switch materialStyle {
        case "ultraThin": return .underWindowBackground
        case "regular": return .headerView
        case "thick": return .popover
        default: return .hudWindow
        }
    }

    /// Contrast of primary text against the worst-case background (exposed for tests).
    public var primaryContrast: Double { backgrounds.map { RGBAColor.contrastRatio(primaryRGB, $0) }.min() ?? 1 }
    public var secondaryContrast: Double {
        backgrounds.map { RGBAColor.contrastRatio(primaryRGB.over($0, alpha: secondaryOpacity), $0) }.min() ?? 1
    }
    public var titleContrast: Double { backgrounds.map { RGBAColor.contrastRatio(titleRGB, $0) }.min() ?? 1 }
    public var accentContrast: Double { backgrounds.map { RGBAColor.contrastRatio(accentRGB, $0) }.min() ?? 1 }
}

private struct ZonePaletteKey: EnvironmentKey {
    static let defaultValue = ZonePalette.fallback
}

extension EnvironmentValues {
    public var zonePalette: ZonePalette {
        get { self[ZonePaletteKey.self] }
        set { self[ZonePaletteKey.self] = newValue }
    }
}
